
######################################################################################################
# The utxo module provides methods to manage unspent transaction outputs.
# Unspent transaction amounts are kept in an in-memory  database called the chainstate database.
# chainstate is a key-value store (in terms of Python it is a dictionary).
# The database is built by scanning transactions in the blockchain.
#
# The chainstate database has two main functions: firstly it lets us compute the balances in a wallet,
# secondly it prevents double spending. Double spending occurs when a balance is attempted to be
# spent twice.
########################################################################################################

import rcrypt
import tx as txmod
import pdb
import logging
import blockchain as bchain

# logging for debugging
# logging.basicConfig(filename="debug.log", level=logging.DEBUG)
log = logging.getLogger("debug.log")

###############################################################################################################
# we need a container structure to hold unspent transaction values. Our container will be a dictionary
# which has a concatenated transaction id and an index as it's key and a dictionary object as a key value.
# We will look at the structure of these value elements later.
# Firstly we specify an empty chainstate.
###############################################################################################################

chainstate = {}

###############################################################################################################
#
# Each element of the chainstate database has the following structure:
#
#  transactionid + '_' +str(vout_index) = {
#                                           block_height,
#                                           mdhash
#                                           value,
#                                           is_coinbase
#                                    }
#
#
# The key is constructed by concatenating the id of a transaction with a vin['vout'] element (thus keys are
# always unique)
# vin[vout] is the index into the vout element of a previous transaction those vout[index] value is
#  being spent in the present transaction.
#
# block_height refers to the block in which the previous transaction is found.
# mdhash is the Ripemd-160 hash of the SHA-256 hash of the public key person unlocking the value.
# value is the spendable amount from the previous transaction's vout element.
# The is_coinbase attribute is 1 if the transaction is a coinbase transaction and zero otherwise.
#
# Coinbase transactions are newly minted currency and hence do not have any previous transaction inputs.
# The first transaction in a block is always a coinbase transaction.
#
#
###############################################################################################################


###############################################################################################################
# The build_chainstate function makes the chainstate database by iterating through the blocks on the blockchain.
#
# The algorithm is simple, firstly for each transaction add the vout values to the chainstate database
# and then for each vin element in a transaction, remove the previous vout elements which are being
# consumed by this transaction. Recall that all of amount in a previous transaction's vout element must be
# consumed by the present transaction's vin element.
# 
###############################################################################################################

def build_chainstate() -> "bool":
   
    # empty the chainstate DB
    chainstate.clear()
    # The height of the current block being processed 
    block_height = 0

    # iterate through all of the blocks of the blockchain
    for block in bchain.blockchain:
        chainstate_manage_blocks(block)

    return True


###############################################################################################################
# chainstate_manage_blocks: adds transactions in a block to the chainstate
###############################################################################################################

def chainstate_manage_blocks(block: 'dictionary') -> 'bool':
   
    block_height = len(bchain.blockchain)
    transaction_number = 0

    # iterate through all of the transactions in the received block
    for tx in block['tx']:
            
        # compute chainstate elements for the coinbase transaction and 
        # genesis block transactions (block height is 1)
        # note that transactions in the genesis block do not have
        # antecedent blocks. A coinbase transaction has only
        # one vin element and is the first transaction in a block
        if transaction_number == 0 or block_height == 1:
            if validate_coinbase_transaction(tx) == False:
                    raise ValueError('chainstate invalid coinbase transaction')
            add_coinbase_tx_to_chainstate(block_height, tx)

        # for ordinary transactions, validate the transaction and if valid add
        # the unspent amounts (vout values) to the chainstate database
        else:
            if validate_chainstate_transaction(tx) == False:
                raise ValueError('chainstate invalid tx')
            add_tx_to_chainstate(block_height, tx)
            
            transaction_number += 1

    return True



###############################################################################################################
# The add_coinbase_transaction_to_chainstate function adds a coinbase transaction to the chainstate DB.
# This function receives the height of the block in which the transaction will exist, and a transaction object.
# Returns True
###############################################################################################################

def add_coinbase_tx_to_chainstate(block_height: "integer", tx: "dictionary") -> "bool":  
        # pdb.set_trace()

        ######################################################################
        # iterate through the vout list and construct a chainstate element
        # for each list element
        ######################################################################c

        for index, vout in enumerate(tx['vout']):

             # compute a dictionary key for a chainstate element
             key = tx['transactionid'] + '_' + str(index)

             # add the transaction fragment to the chainstate database
             chainstate[key] = {
                                'height': block_height,
                                'mdhash': vout['mdhash'],
                                'value':  vout['value'],
                                'is_coinbase': 1    
                               }
        
        return True

     
###############################################################################################################
# The add_transaction_to_chainstate function adds a transaction to the chainstate database
# This function receives the height of the current block being processed, and a transaction object.
# Returns True or False if there is an error
###############################################################################################################

def add_tx_to_chainstate(block_height: "integer", tx: "dictionary") -> "bool":  


        ######################################################################
        # iterate through the vout list and construct a chainstate element
        # for each vout list element
        ######################################################################
        index = -1
        for vout in tx['vout']:

             # compute a dictionary key for a chainstate element
             index += 1
             key = tx['transactionid'] + '_' + str(index)

            # add the transaction fragment to the chainstate database
             chainstate[key] = {
                                'height': block_height,
                                'mdhash': vout['mdhash'],
                                'value':  vout['value'],
                                'is_coinbase': 0    
                                }

        # remove previous transaction outputs that have been consumed by the present transaction
        # construct the key to the output being consumed and delete the key and value from the
        # chainstate Database
        for vin in tx['vin']:
            key = vin['transactonid'] + '_' + str(vin['vout'])
            if chainstate.get(key):
                del chainstate[key]
            else:
                logging.debug('failed to delete chainstate record - key not found')
                return False

        return True



###############################################################################################################
# validate_chainstate_transaction tests whether all of the inputs of a transaction point to valid outputs
# of a previous transaction.
# receives a transaction which is not a coinbase transaction as a dictionary object.
# Returns True if the inputs are valid False otherwise
###############################################################################################################

def validate_chainstate_transaction(tx: "dictionary") -> "bool":

     #pdb.set_trace()
     spent_amount     = 0
     spendable_amount = 0

     # the transaction must contain inputs and outputs
     if len(tx['vin']) == 0: 
         return False

     if len(tx['vout']) == 0: 
         return False

     # iterate through all of the vin elements of the transaction
     for index, vin in enumerate(tx['vin']):

        # set a pointer to a fragment of a previous transaction
        ptr = vin['txid'] + '_' + str(vin['vout'])

        # verify that the previous transaction fragment exists in the chainstate DB
        # it is referred to by value of the vout element
        if chainstate.get(ptr) == None:
            logging.debug('validate_chainstate_transaction: invalid chainptr, no previous transaction')
            return False

        # test that inputs of the present transaction are valid (extract values 
        # from the vout array of the previous transaction)
        if chainstate[ptr]['value'] <= 0:
                logging.debug('validate_chainstate_transaction: value <= 0')
                return False

        spendable_amount += chainstate[ptr]['value']
     
     # spent amount must be less than or equal to the spendable inputs
     for vout in tx['vout']:
         spent_amount += vout['value']

     # the spent amount must be a positive integer
     if spent_amount <= 0:
         logging.debug('validate_chainstate_transaction: spent amount <= 0')
         return False

     # the spent amount must be less than or equal to the spendable amount
     if spent_amount > spendable_amount:
         logging.debug('validate_chainstate_transaction: spendable amount <= 0')
         return False
     
     return True




###############################################################################################################
# validate_coinbase_transaction tests the validity of a coinbase transaction or genesis block transactions.
# receives a coinbase transaction or a genesis block transaction as a dictionary object.
# Note that a coinbase transaction has only one vin element.
# Returns True if the inputs are valid False otherwise
###############################################################################################################

def validate_coinbase_transaction(tx: "dictionary") -> "bool":

     if len(tx['vout']) == 0:
        logging.debug('validate_coinbase_transaction:no vout elements')
        return False

     # coinbase values and genesis block values must be greater than or equal to zero
     for vout in tx['vout']:
         if vout['value'] <= 0:
             logging.debug('validate_coinbase transaction: vout value <= 0')
             return false
     
     return True


