

<script type="text/javascript">

  /*********************************************************
   * Set a user for real time bitcoin trading
   ********************************************************/

  /*********************************************************
   * Global Variables
   * Tab lock - a tab cannot be accessed if the TAB_LOCK
   *            is set
   *********************************************************/

  var TAB_LOCK    = true;
  var ACTIVE_TAB  = '';

  var USER_ACCOUNT_ARRAY = [];
  var USER_USD_FUNDS     = 0;

  var USER_HISTORY_ARRAY = [];

  var USER_LICENSE       = null;


  /**********************************************
   * flags for setInterval in refresh tab code
   *********************************************/
  leaderboardRefreshFlag = false;


  /********************************************
   * portfolio object: the users portfolios
   ********************************************/

  PORTFOLIO_OBJECT = [];

  /********************************************
   * currently selected sim in the views
   ********************************************/
  GLOBAL_SELECTED_SIM_NAME = null;


  /********************************************
   * initialize the usersusd funs
   ********************************************/

  <% if user_signed_in? %>

    USER_USD_FUNDS = <%= raw current_user.funds_usd.to_json %>
    USER_USD_FUNDS = parseFloat(USER_USD_FUNDS).toFixed(2);

  <% end %>

</script>


<script type="text/javascript">

  /*************************************************************
   *  get the users account information periodically
   *  gets the users account (string) not the user object
   ************************************************************/
  function globalGetUserAccountArray() {

    <% if user_signed_in? %>

    //alert("send message to update the globalUserArray");

    var user_name = <%= raw current_user.name.to_json %>
    App.account.speak({'message': "global-get-user-account", user_name: user_name});

    //alert("sent by..." + user_name);

    <% end %>

  }

  // Refresh The User Account Every Minute

  <% if user_signed_in? %>
    setInterval(globalGetUserAccountArray, 60 * 1000);
  <% end %>



  /**************************************************************
   * reply to global_get_account_info
   * sets the users account array into a globally accessible
   * array
   *************************************************************/

  function replyToGlobalGetUserAccount(user_record) {

  // alert("replyToGlobalGetUserAccount = " + JSON.stringify(user_record));

    // error
    if (user_record === false) {
      alert("socket failed to retrieve your user record");
      return;
    }


    try {
      USER_ACCOUNT_ARRAY.length = 0;
      USER_ACCOUNT_ARRAY = JSON.parse(user_record["account"]);
      USER_USD_FUNDS     = user_record["funds_usd"];

      // reconstruct the portfolio object
      initializePortfolio();

    }

    catch(e) {
      USER_ACCOUNT_ARRAY.length = 0;
      alert("socket has failed to parse your account info: " + e.message);
      window.location.href = 'https://symbolticker.com/users/sign_in';
    }

    //alert("global user account array = " + JSON.stringify(USER_ACCOUNT_ARRAY));

  }


</script>




<script type="text/javascript">

  /***************************************************************
   * get the latest exchange rate from the Indicator Controller
  ***************************************************************/

  try {
    var candlestick = <%= raw @last_one_min_candlestick.to_json %>;
    var btemp       = candlestick[0]["candlestick"];

    try {
      btemp = JSON.parse(btemp);
      BTCCURRENCY = btemp['close'];
    }
    catch(e) {
      alert("failed to parse BTC currency");
    }

   // alert("BTCCURRENCY IS = " + BTCCURRENCY.toString());
  }

  catch(e) {
    alert("failed to get the exchange rate: " + e.message)
  }


  /***************************************************
   * Clear all of the the global timers
   ***************************************************/

  for (var ctr = GLOBAL_TIMER_ARRAY.length - 1; ctr >= 0; ctr--) {
    clearInterval(GLOBAL_TIMER_ARRAY[ctr]);
    GLOBAL_TIMER_ARRAY.splice(ctr, 1)
  }


  /********************************************************
   * adds a new visitor to the Redis visitor counter
   * uses XHTMLHttpRequest
   ********************************************************/

  function newVisitorMessage() {
    var remote_ip = <%= raw $remote_ip.to_json  %>

    // cannot pass dots in url parameter
    remote_ip = remote_ip.replace(/\./g, '_');
    //alert(remote_ip);

    var xhr = new XMLHttpRequest();
    var url = "https://symbolticker.com/visitor/new/" + remote_ip;
    xhr.open('GET', url, true);
    xhr.send();

    xhr.addEventListener("readystatechange", processAddVisitor, false);
    xhr.onreadystatechange = processAddVisitor;

    /***************************
    // Add Visitor callback
     **************************/
    function processAddVisitor() {

      if (xhr.readyState == 4 && xhr.status == 200) {

        var response = xhr.responseText;
        response     = JSON.parse(response);

        //alert("visitor count = " + response["visitor_count"]);

        $(function() {
          document.getElementById("visitor-count").innerHTML = response["visitor_count"];
        })
      }
    }

  }

  newVisitorMessage();

  /**********************************************************
   * process a heartbeat message for a visitor
   *********************************************************/

  function heartbeatMessage() {
    var remote_ip = <%= raw $remote_ip.to_json  %>

    // cannot pass dots in url parameter
    remote_ip = remote_ip.replace(/\./g, '_');
    //alert(remote_ip);

    var xhr = new XMLHttpRequest();
    var url = "https://symbolticker.com/visitor/heartbeat/" + remote_ip;
    xhr.open('GET', url, true);
    xhr.send();

    xhr.addEventListener("readystatechange", processHeartbeat, false);
    xhr.onreadystatechange = processHeartbeat;


    /***************************
     // heartbeat callback
     **************************/

    function processHeartbeat() {

      if (xhr.readyState == 4 && xhr.status == 200) {

        var response = xhr.responseText;
        response     = JSON.parse(response);

       // alert("heartbeat count = " + response["visitor_count"]);

        $(function() {
          document.getElementById("visitor-count").innerHTML = response["visitor_count"];
        })
      }
    }

  }

  /**********************************
   * send a heartbeat every minute
   **********************************/
  HEARTBEAT_TIMER_ID = setInterval(heartbeatMessage, 60000);
  GLOBAL_TIMER_ARRAY.push(HEARTBEAT_TIMER_ID);

  </script>


  <script type="text/javascript">


  /********************************************************
   * Initialize The Portfolio Object.The portfolio object
   * contains valuations for each of the user's sims. We
   * update the portfolio object on the clientside; this
   * saves having to make queries through websockets
   ********************************************************/

   function initializePortfolio() {
     var ctr, simObject, account;

    try {
         PORTFOLIO_OBJECT.length = 0;

         account = USER_ACCOUNT_ARRAY;

      for (ctr = 0; ctr < account.length; ctr++) {
        simObject = {};

        simObject["sim_name"] = account[ctr]["sim_name"];
        simObject["end_date"] = account[ctr]["end_date"];
        simObject["usd"]      = account[ctr]["usd"];
        simObject["btc"]      = account[ctr]["btc"];

        simObject["initial_capital"]  = account[ctr]["initial_capital"];
        simObject["btc_dollar_value"] = account[ctr]["btc_dollar_value"];
        simObject["commission"]       = account[ctr]["commission"];
        simObject["capital_account"]  = account[ctr]["capital_account"];
        simObject["portfolio_value"]  = account[ctr]["portfolio_value"];

        PORTFOLIO_OBJECT.push(simObject);

        //alert("portfolio initialization= " + JSON.stringify(PORTFOLIO_OBJECT));

      }

    }
    catch(e) {
      alert("portfolio initialization error: " + e.message)
    }


  }

</script>


<script type="text/javascript">

  /**********************************************************
   * Get user account info on start up
   *********************************************************/

  <% if user_signed_in? %>

  try {

        USER_ACCOUNT_ARRAY = <%= raw current_user.account.to_json %>;
        USER_ACCOUNT_ARRAY = USER_ACCOUNT_ARRAY.replace(/=>/g, ":");

        USER_LICENSE       = <%= raw current_user.license_accepted.to_json %>;

        USER_ACCOUNT_ARRAY = JSON.parse(USER_ACCOUNT_ARRAY);

       // initialize the portfolio object
        initializePortfolio();
  }
  catch(e) {
    alert("failure parsing the users account array on signin:" + e.message);
    window.location.href = 'https://symbolticker.com/users/sign_in';
  }

  <% end %>

</script>



<script type="text/javascript">

  /*****************************************************
   * initialize the user history
   * receives an array of user trades
   ****************************************************/

  USER_HISTORY_ARRAY = <%= raw $user_history.to_json %>;

  //alert("initialized history array: " + JSON.stringify(USER_HISTORY_ARRAY));

  /****************************************
   * logout if the history array is null
   * simulations have been deleted
   ***************************************/

  if (USER_HISTORY_ARRAY === null) {
    location.href = "http://symbolticker.com/users/sign_out"
  }


</script>


<script type="text/javascript">

    /**********************************************************
     * activate the tabs once the tab lock is released
     **********************************************************/
  function activateTabs() {


     $(function() {

       if (TAB_LOCK === false) {
         $("#account-menu-tab").attr("data-toggle", "tab").addClass("indicator-menu-text");
         $("#simulation-menu-tab").attr("data-toggle", "tab").addClass("indicator-menu-text");
         $("#trade-menu-tab").attr("data-toggle", "tab").addClass("indicator-menu-text");
         $("#pl-menu-tab").attr("data-toggle", "tab").addClass("indicator-menu-text");
         $("#history-menu-tab").attr("data-toggle", "tab").addClass("indicator-menu-text");
         $("#leaderboard-menu-tab").attr("data-toggle", "tab").addClass("indicator-menu-text");
         $("#help-menu-tab-id").attr("data-toggle", "tab").addClass("indicator-menu-text");
         $("#promotions-menu-tab-id").attr("data-toggle", "tab").addClass("indicator-menu-text");

       }
       else {
         setTimeout(activateTabs, 250);
       }
     })

  }

  $("#help-menu-tab-id").addClass("grey");

  setTimeout(activateTabs, 250);

</script>


<script type="text/javascript">

  var TMP;

  /****************************************************************
   * listen for tab events
   ****************************************************************/

  $(document).on( 'shown.bs.tab', 'a[data-toggle="tab"]', function (e) {
      var activeTab = $(e.target).text();         // active tab
      // alert(activeTab);

       var prevTab = $(e.relatedTarget).text();  // previous tab
      // alert(prevTab);

    /****************************
    // previous tab logic
     ***************************/

    if (prevTab === 'bitcoin exchange') {
       $("#indicator-tab").hide();
       $("#myTabbedMenu").removeClass("#black-wrapper").addClass("white-wrapper")
    }

    else if (prevTab === 'simulation') {
        TMP = GLOBAL_TIMER_ARRAY.indexOf(SIMULATION_TIMER_ID);

      if (TMP >= 0) {
          clearInterval(TMP);
          GLOBAL_TIMER_ARRAY.splice(TMP, 1);
        }
    }

    else if (prevTab === 'trade') {
      TMP = GLOBAL_TIMER_ARRAY.indexOf(TRADE_TIMER_ID);

      if (TMP >= 0) {
        clearInterval(TMP);
        GLOBAL_TIMER_ARRAY.splice(TMP, 1);
      }

    }


    else if (prevTab === 'profit and loss statement') {
      TMP = GLOBAL_TIMER_ARRAY.indexOf(PL_SIM_TIMER_ID);

      if (TMP >= 0) {
        clearInterval(TMP);
        GLOBAL_TIMER_ARRAY.splice(TMP, 1);
      }

      TMP = GLOBAL_TIMER_ARRAY.indexOf(PL_HISTORY_TIMER_ID);

      if (TMP >= 0) {
        clearInterval(TMP);
        GLOBAL_TIMER_ARRAY.splice(TMP, 1);
      }

      TMP = GLOBAL_TIMER_ARRAY.indexOf(PL_PL_TIMER_ID);

      if (TMP >= 0) {
        clearInterval(TMP);
        GLOBAL_TIMER_ARRAY.splice(TMP, 1);
      }

    }


    else if (prevTab === 'history') {
      TMP = GLOBAL_TIMER_ARRAY.indexOf(HISTORY_TIMER_ID);

      if (TMP >= 0) {
        clearInterval(TMP);
        GLOBAL_TIMER_ARRAY.splice(TMP, 1);
      }
    }


    else if (prevTab === 'leaderboard') {

      TMP = GLOBAL_TIMER_ARRAY.indexOf(LEADERBOARD_TIMER_ID);

      if (TMP >= 0) {
        clearInterval(TMP);
        GLOBAL_TIMER_ARRAY.splice(TMP, 1);
      }

    }


      /****************************
       * present tab logic
       ***************************/

    if (activeTab === 'bitcoin exchange')
    {
        $("#indicator-tab").addClass("black-wrapper").show();
        $("#myTabbedMenu").removeClass("white-wrapper").addClass("black-wrapper");

        ACTIVE_TAB = 'bitcoin';
        refreshIndicatorsTab();
    }

    else if (activeTab === 'account')
    {
      ACTIVE_TAB = 'account';
      refreshAccountTab();
    }

    else if (activeTab === 'simulation')
    {
      ACTIVE_TAB = 'simulation';
      refreshSimulationTab();
    }

    else if (activeTab === 'trade')
    {
      ACTIVE_TAB = 'trade';
      refreshTradeTab();
    }

    else if (activeTab === 'profit and loss statement')
    {
      ACTIVE_TAB = 'profit and loss statement';
      refreshProfitTab();
    }

    else if (activeTab === 'trading history')
    {
      ACTIVE_TAB = 'history';
      refreshHistoryTab();
    }

    else if (activeTab === 'leaderboard')
    {
      ACTIVE_TAB = 'leaderboard';
      refreshLeaderboardTab();
    }

  });


</script>


<script type="text/javascript">

  /**********************************************************************
   * establish a socket connection to get the exchange rate
   * Uses port 8080
   **********************************************************************/
  var ws, reconnectId = null;

  connect();

  function connect() {

    ws = new WebSocket("wss://centride.com:8080");

    ws.onclose = function (e) {

      if (reconnectId === null) {
        var rnd = Math.random()*1000;
        reconnectId = setInterval(connect, rnd);
      }
    };

    ws.onopen = function (e) {

      if (reconnectId) {
        clearInterval(reconnectId);
        reconnectId = null;
      }

    };

    ws.onerror = function (e) {
      // alert("client websocket connection error:  " + e.message + "\n");
    };



    ws.onmessage = function (msg) {
      var params;

      try {
        params = JSON.parse(msg.data);
      }
      catch (e) {
        alert("message parse error = " + e.message + "\n");
      }


      /***********************************
       // receive exchange rate data
       // happens every minute
       **********************************/
      //tmp = { "messageType": "exchange_rates", "message": exchangesArray };

      if (params["messageType"] === "exchange_rates") {

        var previousRate = BTCCURRENCY;

        var exchangeArray = params.message;

        //alert("received exchange rate data:  " + JSON.stringify(exchangeArray) +"\n");

        /************************************************
         * set the btcCurrency exchange rate from the
         * symticker property
         * be used to draw the graphs
         ***********************************************/
        var ktr, tmp;

        for (ktr = 0; ktr < exchangeArray.length; ktr++ ) {
          tmp = exchangeArray[ktr].split(":");

          if (tmp[0] === 'symticker') {
            BTCCURRENCY = parseFloat(tmp[1]);

            if (isNaN(BTCCURRENCY) === true) {BTCCURRENCY = previousRate}

            break;
          }
        }


      }

    };

  }  // end of connect function


</script>


<!-- TABBED MENU  -->
  <ul id="myTabbedMenu" class="nav nav-tabs black-wrapper">
    <li class="active"><a data-toggle="tab" href="#home">bitcoin exchange</a></li>
    <li><a id="account-menu-tab" data-toggle="" href="#account" >account</a></li>
    <li><a id="simulation-menu-tab" data-toggle="" href="#simulation">simulation</a></li>
    <li><a id="trade-menu-tab" data-toggle="" href="#trade">trade</a></li>
    <li><a id="pl-menu-tab" data-toggle="" href="#profit-loss">profit and loss statement</a></li>
    <li><a id="history-menu-tab" data-toggle="" href="#history">trading history</a></li>
    <li><a id="leaderboard-menu-tab" data-toggle="" href="#leaderboard">leaderboard</a></li>
    <li><a id="help-menu-tab-id" data-toggle="" href="#help">help</a></li>
    <li><a id="promotions-menu-tab-id" data-toggle="" href="#promotions">promotions</a></li>
  </ul>



<!-- Tabbed CONTENT -->

<div id="tabbed-content" class="tab-content">

    <div id="home" class="tab-pane fade in active">
      <div id="indicator-tab" class="black-wrapper">
       <%= render 'bitcoin_exchange' %>
      </div>
    </div>

    <div id="account" class="tab-pane fade">
      <div id="account-tab" class="white-wrapper">
         <%= render 'account' %>
      </div>
    </div>

    <div id="simulation" class="tab-pane fade">
      <div id="simulation-tab" class="white-wrapper">
       <%= render 'simulation' %>
      </div>
    </div>

    <div id="trade" class="tab-pane fade">
      <div id="trade-tab" class="white-wrapper">
        <%= render 'trade' %>
      </div>
    </div>

    <div id="profit-loss" class="tab-pane fade">
      <div id="profit-loss-tab" class="white-wrapper">
        <%= render 'profit' %>
      </div>
    </div>


    <div id="history" class="tab-pane fade">
      <div id="history-tab" class="white-wrapper">
      <%= render 'history' %>
      </div>
    </div>

    <div id="leaderboard" class="tab-pane fade">
      <div id="leaderboard-tab" class="white-wrapper">
        <%= render 'leaderboard' %>
      </div>
    </div>


    <div id="help" class="tab-pane fade">
      <div id="help-tab" class="white-wrapper">
        <%= render 'help' %>
      </div>
    </div>

  <div id="promotions" class="tab-pane fade">
    <div id="promotions-tab" class="white-wrapper">
      <%= render 'promotions' %>
    </div>
  </div>


</div>

