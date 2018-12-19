/*===================================================================================
 * exchange_rate.js : gets exchange rate data from bitcoin exchanges by connecting
 * to various APIs
 *
 * DAEMON MUST BE STARTED AS ROOT (due to the http server)
 *
 *==================================================================================*/

"use strict";

var fs          = require("fs");
var http        = require("http");
var https       = require("https");

var parseString = require("xml2js").parseString;

var exchangeServer = require("./exchange_server.js");
var crawler        = require("./crawler");

var lastBtceRate     = 0;
var lastBitfinexRate = 0;
var lastGdaxRate     = 0;



/*=======================================
 * Exchange Rate Polling - every minute
 *======================================*/

var EXCHANGE_POLL_INTERVAL =  1 * 60 * 1000;


// ECB poll interval: 2 hours
//var ECB_POLL_INTERVAL      =  2 * 60 * 60 * 1000


/******************************************
 * set up the memwatch module
 ******************************************/

var memwatch = require('memwatch');
var hd;

memwatch.on('stats', function(stats) {
    var diff, hdiff, output;

    if (!hd) {
        hd = new memwatch.HeapDiff();
    } else {
        diff = hd.end();
        hdiff = JSON.stringify(diff);
        fs.appendFileSync("log.exchange.dat", "DIFF : " + hdiff    + "\n\n");
        hd = null;
    }

    output = JSON.stringify(stats);
    fs.appendFileSync("log.exchange.dat", "STATS : " + output  + "\n\n");

});



/*============================================================================
 * ecbCallback : processes data that is received from ecb on the yuan/USD
 * rate
 *===========================================================================*/


function ecbCallback(res) {

    var xml = "";

    try {
      res.on("data", function (data) {
          xml += data;
      });


        res.on("error", function(e) {

            crawler.crawlerInterface('exchange_rate_daemon', 'daemon_exchange_rate.js', 'global', 92,
                'exchange rate daemon started', 'info');


            fs.appendFile("log.exchange.dat", "exchange_rate.js: ECB callback error: " +
                e.message + "\n", function(){});


        });


        res.on("end", function () {

            parseString(xml, function (e, result) {

               if (e) {
                   fs.appendFile("log.exchange.dat", "exchange_rate.js: ECB parse error: " + e.message + "\n", function(){});
                   return;
               }

               // The entire currency list is in XML format
                try {
                      JSON.stringify(result["gesmes:Envelope"]["Cube"][0]["Cube"]["0"]["Cube"][19]["$"]["rate"] );
                   }

                catch(err) {
                  fs.appendFile("log.exchange.dat", "ecbCallback: ECB stringify exception: " + err.message + "\n", function(){}, function(){});
                  return;
               }

                // USD/Cny Rate
                JSON.stringify(result["gesmes:Envelope"]["Cube"][0]["Cube"]["0"]["Cube"][19]["$"]["rate"] );

            });

      });


  }
    catch(e) {
        fs.appendFile("log.exchange.dat", "ecbCallback: unknown exception: " + e.message + "\n", function(){});

    }

}



/*=============================================================================
 * makes a http call to get the  USD/Renminbi rate from the European Central
 * Bank
 * NOTE: DISABLED
 *============================================================================*/

function getEcbUsdRenminbiRate() {

    try {

        http.get("http://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml", ecbCallback);

    } catch (e) {
        fs.appendFile("log.exchange.dat", "exchange_rate.js: getEcbUsdRenminbiRate: " + e.message + "\n", function(){});
    }

}



/**************************************************************************
 * callbackGdax : processes exhange rate data that is received from
 * bitfinex. In particular the USD/BTC rate
 **************************************************************************/

function callbackGdax(res) {

    var buffer = "";

    res.on("data", function(data) {
        buffer += data;
    });

    res.on("end", function() {

        try {
            //fs.appendFileSync("log.exchange.dat", "callbackBitfinex: exchange rate struct - " + buffer + "\n");
            var replyJson  = JSON.parse(buffer);
            lastGdaxRate   = replyJson["data"]["rates"]["BTC"];
        }
        catch(e) {

            crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'callbackGdax', 171,
                'exception: ' + e.message, 'exception');


            lastGdaxRate = "-";
            exchangeServer.sendRates({"gdax": lastGdaxRate});

            fs.appendFile("log.exchange.dat", "callbackGdx: 1 - " + e.message + "\n", function(){});
            return;
        }

        try {
            lastGdaxRate = parseFloat(lastGdaxRate);

            if (lastGdaxRate !== 0) {
                lastGdaxRate = (1 / lastGdaxRate).toFixed(2);
                lastGdaxRate = parseFloat(lastGdaxRate);
            }
            else {
                lastGdaxRate = '-';
            }
        }
        catch(e) {
            lastGdaxRate = "-";
            exchangeServer.sendRates({"gdax": lastGdaxRate});
            return;
        }



         // fs.appendFileSync("log.exchange.dat","GDAX exchange rate = " + lastGdaxRate +  "\n");

        /******************************************
        // send the latest rate
         *****************************************/
        try {
            exchangeServer.sendRates({"gdax": lastGdaxRate});
        }
        catch(e) {

            crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'callbackGdx', 212,
                'exception: ' + e.message, 'exception');

            fs.appendFile("log.exchange.dat", "callbackGDAX 2 - " + e.message + "\n", function(){});


            lastGdaxRate = "-";
            exchangeServer.sendRates({"gdax": lastGdaxRate});
        }

    });

}


/*===============================================================================
 * gets the GDAX USD/BTC rate
 * GDAX returns:
 *
 *
 * API: GET
 * {"data":{"currency":"USD","rates":{"AZN":"1.65","BAM":"1.75","BBD":"2.00",
 * "BDT":"78.39","BGN":"1.75","BHD":"0.377","BIF":"1657.67","BMD":"1.00","BND":"1.36",
 * "BOB":"6.93","BRL":"3.26","BSD":"1.00","BTC":"0.00163400",
 * "BTN":"66.79","BWP":"10.81","BYN":"1.97","BYR":"20026",}}}
 *=============================================================================*/

function getGdaxRate() {

    try {

        https.get("https://api.coinbase.com/v2/exchange-rates", callbackGdax);

    } catch (e) {

        crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'getGdaxRate', 246,
            'http exception: ' + e.message, 'exception');

        lastGdaxRate = "-";
        exchangeServer.sendRates({"gdax": lastGdaxRate});

        fs.appendFile("log.exchange.dat", "GDAX error: " + e.message + "\n", function(){});
    }

}




/**************************************************************************
 * btceCallback : processes exchange rate data that is received from
 * btce. In particular the USD/BTC rate
 **************************************************************************/

function callbackBtce(res) {

    var buffer = "";

    res.on("data", function(data) {
        buffer += data;
    });

    res.on("end", function() {

        try {
       //     fs.appendFile("log.exchange.dat", "callbackBtce: exchange rate struct: " +
       //     buffer + "\n", function(){});

            var replyJson  = JSON.parse(buffer);
            lastBtceRate   = replyJson.ticker.last;
        }
        catch(e) {

            // TODO too many error messages
           // crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'callbackBtce', 286,
           //      'exception: ' + e.message + " : " + buffer, 'exception');

            lastBtceRate = '-';
            exchangeServer.sendRates({"btce": lastBtceRate});
            //fs.appendFile("log.exchange.dat", "callbackBtce: " + e.message + "\n", function(){});

            return;

        }

        // fs.appendFileSync("log.exchange.dat","BTCe exchange rate = " + lastBtceRate +  "\n");

        // send the latest rate to uws
        try {
            lastBtceRate = lastBtceRate.toFixed(2);
            exchangeServer.sendRates({"btce": lastBtceRate});
        }
        catch(e) {

            crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'callbackBtce', 305,
                'exception: ' + e.message, 'exception');

            lastBtceRate = "-";
            exchangeServer.sendRates({"btce": lastBtceRate});

            fs.appendFile("log.exchange.dat", "callbackBtce: " + e.message + "\n", function(){});

        }


    });

}



/*===============================================================================
 * gets the btc-e USD/BTC rate
 * btc-e returns:
 *
 {"ticker":{"high":613.81,
            "low":594.33099,
            "avg":604.070495,
            "vol":3893823.4409,
            "vol_cur":6452.31907,
            "last":604.011,
            "buy":604.011,
            "sell":604,
            "updated":1473025750,
            "server_time":1473025750}}

 * API: GET https://btc-e.com/api/2/btc_usd/ticker
 *=============================================================================*/

function getBtceRate() {

    try {

        https.get("https://btc-e.com/api/2/btc_usd/ticker", callbackBtce);

    } catch (e) {

        crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'getBtceRate', 348,
            'http exception: ' + e.message, 'exception');

        lastBtceRate = "-";
        exchangeServer.sendRates({"btce": lastBtceRate});

        fs.appendFile("log.exchange.dat", "getBtce: " + e.message + "\n", function(){});

    }

}




/********************************************************************************
 * bitfinixCallback : processes exhange rate data that is received from
 * bitfinex. In particular the USD/BTC rate
 ********************************************************************************/

function callbackBitfinex(res) {

    var buffer = "";

    res.on("data", function(data) {
        buffer += data;
    });

    res.on("end", function() {

        try {
            //fs.appendFileSync("log.exchange.dat", "callbackBitfinex: exchange rate struct - " + buffer + "\n");
            var replyJson     = JSON.parse(buffer);
            lastBitfinexRate  = parseFloat(replyJson.last_price);
            lastBitfinexRate  = lastBitfinexRate.toFixed(2);
        }
        catch(e) {
            crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'callbackBitfinex', 385,
                'exception: ' + e.message, 'exception');

            lastBitfinexRate = '-';
        }

         //fs.appendFileSync("log.exchange.dat","Bitfinex exchange rate = " + lastBitfinexRate +  "\n");

        // send the latest rate
        try {
            exchangeServer.sendRates({"bitfinex": lastBitfinexRate});
        }
        catch(e) {

            crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'callbackBitfinex', 399,
                'exception sending rate: ' + e.message, 'exception');

            fs.appendFile("log.exchange.dat", "callbackBitfinex: 2 - " + e.message + "\n", function(){});

            lastBitfinexRate = "-";
            exchangeServer.sendRates({"bitfinix": lastBitfinexRate});
        }

    });

}


/*===============================================================================
 * gets the bitFinix USD/BTC rate
 * btc-e returns:
 *

 * API: GET
 *           {"mid":"613.6",
 *            "bid":"613.44",
 *            "ask":"613.76",
 *            "last_price":"613.46",
 *            "timestamp":"1473029255.251029401"}
 *=============================================================================*/

function getBitfinexRate() {

    try {

        https.get("https://api.bitfinex.com/v1/ticker/btcusd", callbackBitfinex);

    }
    catch (e) {

        crawler.crawlerInterface('exchange rate daemon', 'exchange_rate.js', 'getBitfinexRate', 435,
            'exception: ' + e.message, 'exception');

        lastBitfinexRate = "-";
        exchangeServer.sendRates({"bitfinix": lastBitfinexRate});
        fs.appendFile("log.exchange.dat", "getBitfinexRate: https call error: " + e.message + "\n", function(){});
    }

}


/******************************************************
 * exports
 ******************************************************/


module.exports = {


    /*============================================================================
     * initialize the exchange rate daemons. Queries bitstamp for the latest
     * btc/usd rate
     * updates the rate in exchange-server.js
     *==========================================================================*/


    init: function() {


        // get the initial Bitcoin USD rate from the BTCe exchange
        //getBtceRate();

        // get the initial Bitcoin USD rate from the Bitfinex exchange
        getBitfinexRate();

        // get the initial Bitcoin USD rate from coindesk
        //getCoindeskRate();

        // get the initial Bitcoin USD rate from GDAX
        getGdaxRate();


        // get the rate at specified intervals
      //  setInterval(getBtceRate, EXCHANGE_POLL_INTERVAL);
        setInterval(getBitfinexRate, EXCHANGE_POLL_INTERVAL);
        setInterval(getGdaxRate, EXCHANGE_POLL_INTERVAL);



        /*****************************************
         * ECB queries
         ****************************************/
        setInterval(getEcbUsdRenminbiRate, ECB_POLL_INTERVAL);


    }

};



