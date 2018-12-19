/******************************************************************************************
 * handles payments for symbolticker winners and returns unused funds for users who
 * delete their accounts
 *
 * Algorithm:
 *            [1] Wake up from sleep
 *            [2] read all of the rows in the activities table
 *            [3] if the paid field is false and the pending field is not set in a row
 *                then process this row
 *            [4] get the amount in the payout field and the bitcoin address
 *            [5] Send a socket request to the bitcoin core wallet to pay out the user
 *            [6] No reply is required on the socket
 *            [7] nakamoto will set the paid field and clear the pending field in the
 *                record if payment succeeds
 *
 ******************************************************************************************/

"use strict";

var fs       = require('fs');
var crawler  = require("./crawler");


var PaymentSocket  = require('ws');
var paymentSocket  = null;

var pg = require("pg");


/***********************************************************************
 *  establish a client websocket connection to uws
 *  tries to reconnect if the client cannot send a message to uws
 *  The socket will only send messages; never receive messages
 ***********************************************************************/


/******************************************************************************
 * The socketHeartbeat is needed because the server may be down
 * The readyState of the socket is checked every 5 seconds
******************************************************************************/

setInterval(socketHeartbeat, 5000);

function socketHeartbeat() {

   if (paymentSocket == null) {
       connect();
       return;
   }

   console.log('socket heartbeat ...state = ' + paymentSocket.readyState);

   if(paymentSocket.readyState == paymentSocket.CLOSED || paymentSocket.readyState == paymentSocket.CLOSING) {
        console.log('payment socket is closed');
        crawler.crawlerInterface('payments', 'datasink.js', 'socketHeartbeat', 53,
            "payments socket to uws is down", "error");

        connect();
    }
}

function connect() {
         console.log('connecting payments socket');
        fs.appendFile("log.payments.txt", "connecting payments socket... " + "\n",  function(error) {
            return("append file error, line 41")} );

        paymentSocket = new PaymentSocket('wss://symbolticker.net');


        paymentSocket.onopen = function () {
            console.log('payments socket is open');
            crawler.crawlerInterface('payments', 'payments.js', 'connect', 74,
                "payments socket connected to uws", "info");
    
        };
    
        /******************
         * socket error
         *****************/

        paymentSocket.on('error', function (e) {
            fs.appendFile("log.payments.txt", "connect error: " + e.message + "\n",  function(error) {
                return("append file error, payments.js:connect():line 66")} );
        });

        /*******************
         * socket close
         ******************/

        paymentSocket.on('close', function (e) {
            console.log('payments socket closed');
            crawler.crawlerInterface('payments', 'payments.js', 'connect', 92, "payment socket closed", "error");

            fs.appendFile("log.payments.txt", "close error: " + e.message + "\n",  function(error) {
                return("append file error, payments.js:connect():line 66")});
        });

    }


/**************************************************************************************
 * establish connection to postgres to process activities table
 *************************************************************************************/

function connectPostgres() {


    var connString = "postgres://postgres@localhost/symbolticker_production";

    pg.connect(connString, function (e, client, done) {

        if (e) {
            console.log("postgres symbolticker production database connection error: " + e.message);
        }

        else {

            console.log("postgres connection established");
            processPayments(client);
            done();

        }
    });


}

/******************************************************************************
 * processPayments: entry point to process payments outstanding in the
 * activities table
 ******************************************************************************/

function processPayments(client) {

    var msg;

    fs.appendFile("log.payments.txt", "payments.js#processPayments - entered processPayments\n", function(error) {
        return("append file error, payments.js:processpayments():line 112")} );


    /*****************************************
     * Select records where payments are due
     * and not being processed
     ****************************************/

    var records = client.query("SELECT * FROM activities WHERE paid=0 AND pending=0");

    fs.appendFile("log.payments.txt", "payments.js#processPayments - SQL Query processed\n", function(){});


    /***************************************************
     * loop through the SQL reply processing the rows
     **************************************************/

    records.on('row', function (row) {

        fs.appendFile("log.payments.txt", "payments.js#processPayments - processing activities table row: " +
           JSON.stringify(row) + "\n", function() {});


        /*********************************************
         * send a payment request to the uws server
         ********************************************/

        msg = { messageType: 'payment-request', message: { address: row.bitcoin_address,
            amount: row.payout_btc, payee: row.name, comment: row.description,  id: row.id } };
        msg = JSON.stringify(msg);

        paymentSocket.send(msg, function ack(err) {
            if (err) {
                crawler.crawlerInterface('payments', 'payments.js', 'connect', 149,
                 "failed to send a payment request to uws", "error");

                fs.appendFile("log.payments.txt","processPayments: socket send error: "  + err.message + "\n", function(error) {
                    return("append file error, line 166")} );
            }
            else {
                fs.appendFile("log.payments.txt", "processPayments: payment request sent for:" +
                 row.bitcoin_address + "\n", function(error) {
                    return("append file error, line 171")} );

                /********************************************
                 * set the pending flag on the transaction
                 *******************************************/

                setTxPendingFlag(row.id);

            }
        });

    });  // end of row processing

    fs.appendFile("log.payments.txt", "payments.js#processPayments - exiting processPayments\n", function(){} );

}



/*************************************************************************
 * setTxPendingFlag: sets the payment pending flag on a record
 ************************************************************************/

function setTxPendingFlag(recordId) {

    fs.appendFile("log.payments.txt", "payments.js#setTxPendingFlag - enter\n", function(){} );


    client.query("UPDATE activities SET pending=($1) WHERE id=($2)", [1, recordId],
        function(err,result) {
            if (err) {



                fs.appendFile("log.payments.txt", "setTxPendingFlag: pending column: record update error: " + 
                err.message + "\n", function(){} );
            }
            else {
                // one row should have been updated
                if (result["rowCount"] === 0) {
                    fs.appendFile("log.payments.txt", "setTxPendingFlag: pending column: zero rows updated: " +
                     "\n", function(){} );
                }
                else {
                    fs.appendFile("log.payments.txt", "updateActivitiesRecord: tx pending field updated" + "\n", function(){} );
                }
            }
        });

}


/*****************************************************************************
 * process payments with the activities table periodically
 ****************************************************************************/


setInterval( connectPostgres,  10 * 1000);




