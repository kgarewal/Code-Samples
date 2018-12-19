/****************************************************************************************
 * mempool transactions: gets and decodes raw transactions in the mempool.
 * In order to calculate the total amount and fees of such a transaction, we need the
 * current raw transaction and the previous raw transactions referred to in the vin of
 * the current transaction .
 *
 * dispatches a mempool transaction data structure through a websocket
 ***************************************************************************************/

"use strict";

var fs     = require("fs");
var config = require("../config");

var  http;
var  clientOptions;

var MempoolSocket  = require('ws');
var mempoolSocket;


// We are handling transactions sequentially
var MEMPOOL_TRANSACTION_DONE = true;
var txTimeoutId              = null;



/*======================================================================
 * Array of raw transactions linked to the latest mempool Transaction 
 * structure:  [ rawmemPoolTxID:  { linked transaction}  ]
 *=====================================================================*/

var linkedTxArray = [];


/*==================================================================
 * array to maintain a count of the number of transactions linked
 * to the latest mempool Transaction
 * structure:  [ { mempoolTxID:  count  }, ... ]  
 *==================================================================*/

var totalLinkedTxs  = 0;
var linkedCount     = 0;


/*=======================================
 * latest mempool transaction
*========================================*/

var mempoolTransaction;


/******************************************
 * set up the memwatch module
 ******************************************/

    /*
 var memwatch = require('memwatch');
 var hd;

 memwatch.on('stats', function(stats) {
    var diff, hdiff, output;

    if (!hd) {
        hd = new memwatch.HeapDiff();
    } else {
             diff = hd.end();
             hdiff = JSON.stringify(diff);
             fs.appendFileSync("log.mempool.dat", "DIFF : " + hdiff    + "\n\n");
             hd = null;
    }

    output = JSON.stringify(stats);
    fs.appendFileSync("log.mempool.dat", "STATS : " + output  + "\n\n");

});

*/


/***********************************************************************
 *  tries to reconnect if the client cannot send a message to uws
 ***********************************************************************/

function connect() {

    function makeConnection() {
        var flag = false;

        fs.appendFile("log.mempool.dat", "reconnecting... " + "\n");
        mempoolSocket = new MempoolSocket('wss://centride.com:8080');


        mempoolSocket.on('error', function (e) {
            fs.appendFile("log.mempool.dat", "connect error: " + e.message + "\n");
            if (flag === false) {
                flag = true;
                connect();
            }
        });

        mempoolSocket.on('close', function (e) {
            fs.appendFile("log.mempool.dat", "close error: " + e.message + "\n");
            if (flag === false) {
                flag = true;
                connect();
            }
        });

    }

    setTimeout(makeConnection, 1500);
}

connect();



/*=====================================================================
 * transactionAbort: aborts the transaction by setting the transaction
 * done flag
 *===================================================================*/

function transactionAbort() {

    MEMPOOL_TRANSACTION_DONE = true;
    clearTimeout(txTimeoutId);
    txTimeoutId = null;

    fs.appendFile("log.mempool.dat", "mempoolTransactions.js#transactionAbort: tx aborted" +  "\n");

}




/*====================================================================
 * transactionTimeout: If the transaction does not complete in
 * RAWMEMPOOL_TX_TIMEOUT seconds, this function aborts it
 *===================================================================*/

function transactionTimeout() {

    MEMPOOL_TRANSACTION_DONE = true;

    fs.appendFile("log.mempool.dat", "mempool_transactions.js#transactionTimeout: transaction timed out" +  "\n");

}



/**********************************************************************
 * persist_mempool_transaction : persists a mempool transaction to
 * a file so that the graphs can be drawn when the user enters the
 * network page
 *********************************************************************/

function persistMempoolTransaction(time, value) {

    var array = [];

    try {
        array = fs.readFileSync("./data_mempool.dat");
        array = JSON.parse(array);
    }
    catch(e) {
        fs.appendFile("log.mempool.dat", "transactions_processor#persistMempoolTransaction: exception: " + e.message + "\n");
        array = [];
    }

   array.push( {time: time, value: value});

    while (array.length > 3600) {
        array.splice(0, 1);
    }

    /*************************************
     // persist the mempool transaction
     ************************************/

    fs.writeFile('./data_mempool.dat', JSON.stringify(array), function(err) {
        if (err) {
            fs.appendFile("log.mempool.dat",
                "mempool_transactions.js#persistMempoolTransaction: failed to write transaction to data_mempool.dat file\n");
        }
        else {
            //fs.appendFile("log.mempool.dat", "mempool transaction persisted: " + " \n");
        }

    });


}


/*================================================================================
 *  getAddressMatch:
 *  For a Vout element in the current transaction compares the vout addresses
 *  to the addresses in the previous linked transactions. If a match is found
 *  then we have a change back instance for this particular vout element
 *=======================/=========================================================*/

function  getAddressMatch(currentAddressArray, linkedAddressArray) {
    var ctr;
    var i;

    /*==============================
     * check for an error condtion
     *=============================*/
    if (MEMPOOL_TRANSACTION_DONE === true) {
        return;
    }

    try {
          if (( currentAddressArray instanceof Array) === false) {
              return;
        }


          for (ctr = 0; ctr < currentAddressArray.length; ctr++) {
              for (i = 0; i < linkedAddressArray.length; i++) {
                  if (currentAddressArray[ctr] === linkedAddressArray[i]) {
                      return;
                  }
              }
          }

    }

    catch(e) {
        fs.appendFile("log.mempool.dat", "mempool_transactions:getAddressMatch - exception: " + e.message + "\n");
        transactionAbort();
    }

}



/*================================================================================
 * getAddressesPreviousTransaction
 * Gets all of the addresses in the vout sub-object of a linked transaction
 * Returns an array of addresses in all previous linked transactions
 *         false if there is an error
 *===============================================================================*/

function getLinkedAddresses() {

    /*==============================
     * check for an error condtion
     *=============================*/
    if (MEMPOOL_TRANSACTION_DONE === true) {
        return;
    }

    var ctr, j, k, vinTxId, index, addresses = [];

    try {


        for (k = 0; k < mempoolTransaction.vin.length; k++) {
            vinTxId = mempoolTransaction.vin[k].txid;
            index   = +mempoolTransaction.vin[k].vout;

            for (ctr = 0; ctr < linkedTxArray.length; ctr++) {
                if (linkedTxArray[ctr].txid !== vinTxId) {
                    continue;
                }

                if (linkedTxArray[ctr].vout[index] === undefined) {
                    continue;
                }

                if (( linkedTxArray[ctr].vout[index].scriptPubKey.addresses instanceof Array ) === false) {
                    break;
                }

                for (j = 0; j < linkedTxArray[ctr].vout[index].scriptPubKey.addresses.length; j++) {

                    addresses.push(linkedTxArray[ctr].vout[index].scriptPubKey.addresses[j]);
                }
            }

        }

    }

    catch(e) {
        fs.appendFile("log.mempool.dat", "mempool_transactions:getLinkedAddresses: exception: " + e.message + "\n");
        transactionAbort();
        return;
    }

    return addresses;

}



/**************************************************************************
 * computeTransaction:
 **************************************************************************/

function computeTransaction() {

    var addresses, change = 0, ctr, packet = {}, matchFound, trade = {};

    /*==============================
     * check for an error condtion
     *=============================*/
    if (MEMPOOL_TRANSACTION_DONE === true) {
        return;
    }

    addresses = getLinkedAddresses();

    if (addresses === false) {
        fs.appendFile("log.mempool.dat", "mempool_transactions:computeTransaction: getLinkedAddress returned false" + "\n");
        transactionAbort();
        return;
    }

    /*=====================================
     * make a package for uws
     *====================================*/

    packet.txid          = mempoolTransaction.txid;
    packet.version       = mempoolTransaction.version;
    packet.locktime      = mempoolTransaction.locktime;
    packet.blockhash     = mempoolTransaction.blockhash;
    packet.confirmations = mempoolTransaction.confirmations;
    packet.time          = mempoolTransaction.time;
    packet.blocktime     = mempoolTransaction.blocktime;

    // total value of the transaction
    packet.value = 0;


    /******************************************************
     * look for a change back to the spender address match
     ******************************************************/

    for (ctr = 0; ctr < mempoolTransaction.vout.length; ctr++) {
        matchFound = getAddressMatch(mempoolTransaction.vout[ctr].scriptPubKey.addresses, addresses);

        if (matchFound) {
            packet.value += mempoolTransaction.vout[ctr].value;
            change       += mempoolTransaction.vout[ctr].value;
        }
        else {
            packet.value += mempoolTransaction.vout[ctr].value;
        }
    }

    // size
    packet.size = mempoolTransaction.size;

    // transaction fee
    packet.fee  = mempoolTransaction.fee;

    //  priorities
    // console.log("mempooltransaction: mempool transaction = " + JSON.stringify(mempoolTransaction));

    packet.startingpriority = mempoolTransaction.startingpriority;
    packet.currentpriority  = mempoolTransaction.currentpriority;

    // height
    packet.height = mempoolTransaction.height;

    // The change back from the transaction
    packet.change = change;


    /*********************************
     * send through the websocket
     ********************************/
    var   tmp;

    tmp = { "messageType": "mempool_transaction", "message": packet };
    tmp = JSON.stringify(tmp);


    /****************************************
     * broadcast the transaction data through
     * uws to all connected clients
     ****************************************/

    // fs.appendFile("log.mempool.dat", "ready to send tx data to uws : " + tmp + "\n");

    try {
        mempoolSocket.send(tmp, function ack(error) {
            if (error) {
                fs.appendFile("log.mempool.dat", "failed to send tx data " + "\n");
            }
            else {
               // fs.appendFile("log.mempool.dat", "tx data sent" + "\n");
            }

        });

    }
    catch(e) {
        fs.appendFile("log.mempool.dat", "failed to send tx data " +  e.message  + "\n");
    }




    /**************************************************
     * send trade data to build virtual candlesticks
     **************************************************/

    trade.volume  = (packet.value - packet.change);

    tmp = { "messageType": "candlestick_transaction", "message": trade };
    tmp = JSON.stringify(tmp);


    /****************************************
     * broadcast the trade data through
     * uws to all  uws connected clients
     ***************************************/

    // fs.appendFile("log.mempool.dat", "ready to send trade data to uws : " + tmp + "\n");

    try {
        mempoolSocket.send(tmp, function ack(error) {
            if (error) {
                fs.appendFile("log.mempool.dat", "failed to send trade data " + "\n");
            }
        });
    }
    catch(ex) {
        fs.appendFile("log.mempool.dat", "failed to send trade data " + ex.message + "\n");
    }



    /****************************************************
     * persist the mempool transaction  so that users can
     * draw the graphs when entering the network page
     ***************************************************/

    persistMempoolTransaction(packet.time, trade.volume);
}



/*******************************************************************************
 * decodeMempoolTransaction: decodes a mempool transaction and the transactions
 * linked to it.
 * Packages it for delivery through a websocket
 *******************************************************************************/

function decodeMempoolTransaction() {

    /*==============================
     * check for an error condition
     *=============================*/
    if (MEMPOOL_TRANSACTION_DONE === true) {
        return;
    }

    computeTransaction();

    MEMPOOL_TRANSACTION_DONE = true;

}



/**********************************************************************************
 * pushLinkedTransaction : pushes a linked transaction onto the linkedTxArray
 * Receives the complete bitcoin reply for a linked transaction
 *********************************************************************************/

function pushLinkedTransaction(bitcoinReply) {

    // push the linked transaction onto linkedTxArray
    linkedTxArray.push(bitcoinReply.result);

    // increment the linked count
    linkedCount++;

    /***************************
    // Call the decoder
    ***************************/

    if (totalLinkedTxs === linkedCount) {
        decodeMempoolTransaction();
    }

}



/****************************************************************************
 * callback gets the raw transaction linked to the mempool transaction
 ***************************************************************************/

var callbackLinkedTransaction = function(res) {
    var buffer = "", replyJson;

    /*==============================
     * check for an error condtion
     *=============================*/
     if (MEMPOOL_TRANSACTION_DONE === true) {
         return;
     }


    /*=====================================================
     * could not get the linked transaction. just abort
     * the whole transaction
     *====================================================*/
    if (res.statusCode !== 200) {
        fs.appendFile("log.mempool.dat", "mempool_transactions:callbackLinkedTransaction: http response error - " +
            res.statusCode +"\n");
        transactionAbort();
        return;
    }

    try {

        res.on('data', function (data) {
            buffer += data;
        });

        res.on("end", function () {

            try {
                replyJson = JSON.parse(buffer);
            }
            catch (e) {
                fs.appendFile("log.mempool.dat", "callbackLinkedTransaction: parse error - " + e.message + "\n");
                // abort the whole transaction
                transactionAbort();
                return;
            }

            if (replyJson.error !== null) {
                fs.appendFile("log.mempool.dat", "mempool_transactions:callbackLinkedTransaction - " + replyJson["error"] + "\n");

                // abort the whole transaction
                transactionAbort();
                return;
            }

            // push the linked transaction onto the linkedTxArray
            pushLinkedTransaction(replyJson);

        });

    }

    catch(e) {
        fs.appendFile("log.mempool.dat", "mempool_transactions:callbackLinkedTransaction: exception - " + e.message +  "\n");
        transactionAbort();
    }

};


/*************************************************************************************
 * queryLinkedRawTransactions: get the linked raw transactions those outputs are
 * the inputs for the latest mempool transaction
 *************************************************************************************/

var queryLinkedRawTransactions = function() {

    var ctr, req, query;

    /*****************************************************************
     * For each transaction id in the vin array of the mempool
     * transaction object, fire a raw transaction query to get the
     * linked transaction
     *****************************************************************/

    for (ctr = 0; ctr < mempoolTransaction.vin.length; ctr++) {

        /*==============================
         * check for an error condition
         *=============================*/
        if (MEMPOOL_TRANSACTION_DONE === true) {
            return;
        }


        try {
            /*********************************************************
             set up the query to get the linked transactions
             notice how the id is constructed.  It references the
             transaction to which the fetched transactions are linked
            *********************************************************/

            query = JSON.stringify({ method: "getrawtransaction",
                params: [mempoolTransaction.vin[ctr].txid, 1], id: mempoolTransaction.txid });


            clientOptions.headers["Content-Length"] = query.length;
            clientOptions.headers["Content-Type"]   = "application/json";
            clientOptions.headers.Connection        = "close";

            req = http.request(clientOptions, callbackLinkedTransaction);

            req.on("error", function(e) {
                fs.appendFile("log.mempool.dat", "mempool_transactions:queryLinkedRawTransactions: http request error " +
                    e.message + "\n");
                transactionAbort();
            });

            req.write(query);
            req.end();
        }

        catch (e)
        {
            fs.appendFile("log.mempool.dat", "mempool_transactions:queryLinkedRawTransactions: exception - " + e.message +  "\n");
            transactionAbort();
            return;
        }

    }

};


/*********************************************************************************************
 * saveMemPoolTransaction:
 * Receives a raw mempool transaction object
 *********************************************************************************************/

var saveMemPoolTransaction = function(memPoolObject) {

    // set the mempoolTransaction object

    mempoolTransaction.locktime      = memPoolObject.locktime;
    mempoolTransaction.vin           = memPoolObject.vin;
    mempoolTransaction.vout          = memPoolObject.vout;
    mempoolTransaction.blockhash     = memPoolObject.blockhash;
    mempoolTransaction.confirmations = memPoolObject.confirmations;
    mempoolTransaction.blocktime     = memPoolObject.blocktime;
    mempoolTransaction.version       = memPoolObject.version;


    /*=========================================================
     * Set the total linked transactions for this transaction
     *========================================================*/
    totalLinkedTxs = mempoolTransaction.vin.length;


    /****************************************************
    // we will ignore transactions where the inputs are
    // more than 4, since these are probably
    // consolidation actions for small change
    ****************************************************/

    if (totalLinkedTxs > config.LINKED_TRANSACTIONS_CUTOFF)  {
        fs.appendFile("log.mempool.dat", "total linked transaction is greater than the cutoff\n");
        transactionAbort();
        return;
    }


    /****************************************************
     * get all of the previous transactions that are
     * linked to this mempool transaction
    ******************************************************/

   queryLinkedRawTransactions();

};



/***********************************************************************************
 * callbackMempoolTransaction: gets the raw transaction record for a mempool
 * transaction
 ***********************************************************************************/

var callbackMempoolTransaction = function(res) {
    var buffer = "", replyJson;

    if (res.statusCode !== 200) {
        fs.appendFile("log.mempool.dat", "mempool_transactions:callbackMempoolTransaction: http status error: " +
            res.statusCode + "\n");
        transactionAbort();
        return;
    }

    try {

        res.on("data", function(data) {
            buffer += data;
        });

        res.on("end", function() {

            try {
                replyJson = JSON.parse(buffer);
            }
            catch (e) {
                fs.appendFile("log.mempool.dat", "callbackMempoolTransaction: parse error - " + e.message + "\n");
                transactionAbort();
                return;
            }

            if (replyJson.error !== null) {
                fs.appendFile("log.mempool.dat", "callbackMempoolTransaction: bitcoind error - " +
                    replyJson.error + "\n");
                transactionAbort();
                return;
            }

            /*************************************
            // save the raw mempool transaction
            *************************************/
            saveMemPoolTransaction(replyJson.result);

        });

    }

    catch(e) {
        fs.appendFile("log.mempool.dat",  "mempool_transactions:callbackMempoolTransaction: exception" + e.message + "\n");
        transactionAbort();

    }

};


/*************************************************************
 * Exports
 ************************************************************/

module.exports = {

    /*****************************************************************************
     * fetches the raw transaction for a mempool transaction,
     * receives: the latest transaction in the mempool
     ****************************************************************************/

    processMempoolTransaction: function(mempoolTx) {
        var req, query;

        fs.appendFile("log.mempool.dat", "mempool_transactions#processMempoolTransaction: enter processing for a new transaction" + "\n");

        /********************************************************
         * return if the current transaction is still processing
         *******************************************************/
        if (MEMPOOL_TRANSACTION_DONE === false) {
            fs.appendFile("log.mempool.dat", "mempool_transactions#processMempoolTransactions - mempool transaction not done" + "\n");
            return;
        }

        fs.appendFile("log.mempool.dat", "starting processing a new transaction" + "\n");

        MEMPOOL_TRANSACTION_DONE = false;

        if (txTimeoutId) {
            clearTimeout(txTimeoutId);
            txTimeoutId = null;
        }

        /************************************
         * clean the linked Transactions
         * array and variables
         ***********************************/
         linkedTxArray.length = 0;
         linkedCount    = 0;
         totalLinkedTxs = 0;

         mempoolTransaction = mempoolTx;


        /****************************************
         * get the raw transaction for the
         * received mempool transaction ID
         ***************************************/
        try {

           // set up the query that is to be executed
            query = JSON.stringify({ method: "getrawtransaction", params: [mempoolTransaction.txid, 1],
                id: "getrawmempool" });

            // the connection option is required by the simulator
            clientOptions.headers["Content-Length"] = query.length;
            clientOptions.headers["Content-Type"]   = "text/plain";
            clientOptions.headers.Connection        = "close";

            req = http.request(clientOptions, callbackMempoolTransaction);

            req.on("error", function (e) {
                fs.appendFile("log.mempool.dat", "mempool_transactions:queryMempoolTransaction: mempool HTTP request error" + e.message + "\n");
                MEMPOOL_TRANSACTION_DONE = true;
            });

            req.write(query);
            req.end();
        }

        catch(e) {
            fs.appendFile("log.mempool.dat",  "mempool_transactions:queryMempoolTransaction: exception" + e.message + "\n");
            MEMPOOL_TRANSACTION_DONE = true;
            return;
        }

        /************************************************************
         * set a timeout to check that the transaction completes
         * within a fixed time
         ************************************************************/

        txTimeoutId = setTimeout( transactionTimeout, config.RAWMEMPOOL_TX_TIMEOUT);

    },


    /*************************************************************************
     * initialize the mempool transactions module
     *************************************************************************/

    init: function(httpClient, options) {

        http = httpClient;
        clientOptions = options;
    }

};


/*********************************************************************
 * Capture uncaught exceptions - restart the daemon with with forever
 ********************************************************************/

process.on("uncaughtException", function (error) {
    console.log("uncaught exception: " + error.message);
    process.exit(1);
});
