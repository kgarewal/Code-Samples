
#########################################################################################################
# The code in this module implements a mining node.
# The node receives transactions over the Internet. When a transaction is received, the node checks the
# transaction for validity. If the transaction is valid, the node ads it to it's list of unconfirmed
# transactions.  and adds it to it's list of unconfirmed transactions. Otherwise the transaction
# is discarded.
#
# The node then takes transactions from this list (called the mempool) and adds it to a candidate
# block to be mined. After enough transactions have been added to this new candidate block the miner begins
# to mine the block.
# If this miner is able to successfully mine the block, the block is added to the blockchain and the
# transactions are added to the chainstate database.
#
# The newly mined block is broadcast to other nodes so that they can add the block to their version of
# the blockchain. If the mining operation fails, the transactions are moved back to the unconfirmed list.
##########################################################################################################

import rcrypt
import tx
import blockchain as bchain
import stackprocessor
import utxo
import pdb
import time
import sys
import time
import logging
import helium_config as hconfig

# we will write logging information to debug.log
logging.basicConfig(filename="debug.log", level=logging.DEBUG)


# We firstly specify a list container to hold unconfirmed transactions which are received by the miner 

mempool       = []

# blocks which are received and cannot be added to the head of the blockchain or the parent of
# the head.
orphan_blocks = []

# blocks mined by other miners which are received by this mining node
received_blocks = []


############################################################################################
# The mining_reward function determines the mining reward.
# When a miner successfully mines a block he is entitled to a reward which is a number of
# Helium coins. 
# 
# The reward depends on the number blocks that have been mined so far. The initial reward 
# is hconfig.MINING_REWARD coins. This reward halves every REWARD_INTERVAL blocks.
# The initial values for the reward parameters are set in config.py
############################################################################################

def mining_reward() -> "integer":

     # length of the blockchain
     sz = len(bchain.blockchain) 
     sz = sz // hconfig.REWARD_INTERVAL
     if sz == 0:  return hconfig.MINING_REWARD 

     # determine the mining reward
     mining_reward = hconfig.MINING_REWARD
     for ctr in range(0,sz):
         mining_reward = mining_reward/2
      
     # the mining reward cannot be less than the lowest denominated currency unit 
     if mining_reward < hconfig.NANO_HELIUM: return 0
     return mining_reward


#############################################################################################
# receive_transaction manages transactions received by the miner over the Internet.
# Upon receiving a transaction the miner determines if the transaction already exists in the
# mempool. If the transaction already exists, the incoming transaction is discarded and the
# function returns True.
# Otherwise the miner tests the validity of the transaction and adds it to mempool if it 
# is valid and returns True. If the transaction is invalid, the function returns false.
#
# Note: in production this function would be coded in a seperate process or thread
#############################################################################################

def receive_transaction(transaction: "dictionary") -> "bool":

     # verify that the incoming transaction is valid
     if tx.validate_transaction(transaction) == False:
        logging.debug('receive_transaction: miner received an invalid transaction')
        return False

     # do not add the transaction if it already exists in the mempool
     for trans in mempool:
         if trans == transaction: return True

     # add the transaction to the mempool
     mempool.append(transaction)
     return True
    

###################################################################################################
# The make_candidate_block function makes a candidate block for inclusion in the Helium blockchain.
# A candidate block is created by fetching transactions from the  mempool and adding them to the
# tx list in the candidate block. 
# This function  returns the candidate block or returns False if there is an error or 
# if the mempool is empty.
# This function presumes that a genesis block has  been generated and added to the blockchain.
#
###################################################################################################

def make_candidate_block() -> "dictionary || bool":
    
     # if the mempool is empty the no transactions can be put into 
     # the candidate block
     if len(mempool) == 0: return False
     
     # make a public-private key pair that the miner will use to receive the mining
     # reward as well as the fees for each transaction.
     mdhash = make_miner_keys()

     block = {}

     # create a candidate block
     block['blockid']   = rcrypt.make_id()
     block['version']   = 1
     block['timestamp'] = int(time.time())
     block['difficulty_no']    = hconfig.TARGET
     block['nonce']     = 0
     #  the block height if the block is appended to the blockchain
     block['height'] = len(bchain.blockchain) + 1
     block['confirmations'] = 1

     # set the value of the hash of the previous block's header
     # this induces tamperproofness for the blockchain
     block['previousblockhash'] = bchain.blockchain[-1]['hash']
      
     # calculate the  size (in bytes) of the candidate block 
     # The number 80 is  the byte size of the merkle root and the block header hash,
     # both of which will be calculated later
     size =  sys.getsizeof(block['version'])
     size += sys.getsizeof(block['timestamp']) + sys.getsizeof(block['difficulty_no']) 
     size += sys.getsizeof(block['nonce']) + sys.getsizeof(block['height'])
     size += sys.getsizeof(block['previousblockhash']) + 80


     # list of transactions in the block
     block['tx'] = [] 

     # add the coinbase transaction
     ctx = make_coinbase_transaction(mdhash)
     block['tx'].insert(0, ctx)

     # update the length of the block
     size += sys.getsizeof(block['tx'])

     # add transactions from the mempool to the candidate block until the
     # transactions in the mempool are exhausted or the block
     # attains it's maximum permissible size
     for memtx in mempool:
            # add a transaction fee entry for this transaction       
            memtx = add_transaction_fee(memtx, mdhash)
            # add the transaction to the candidate block
            size += sys.getsizeof(memtx)
            if size <= hconfig.MAX_BLOCK_SIZE:
               block['tx'].append(memtx)
            else:
               break     


    # calculate the merkle root of this block
     ret = bchain.make_merkle_tree(block['tx'], True)
     if ret == False: 
         logging.debug('mining.py: failed to calculate merkle root for the candidate block')
         return False

     block['merkle_root'] = ret

     # setup to calculate the the block header hash for the candidate block
     args = {}
     args['version']           = block['version']
     args['previousblockhash'] = block['previousblockhash']
     args['merkle_root']       = block['merkle_root']
     args['timestamp']         = block['timestamp']
     args['difficulty_no']     = block['difficulty_no']
     args['nonce']             = block['nonce']

     # set the hash of the block header
     block['hash'] = bchain.blockheader_hash(args)

     ##########################################################
     # validate the candidate block and the block transactions
     ##########################################################
     if bchain.validate_block(block) == False: return False

     # At this stage the candidate block has been created and it can be mined
     return block




######################################################################################################
# make_miner_keys: make a public-private key pair that the miner will use to receive his mining 
# reward and the transaction fee for each transaction. This function writes the keys to a file
# and returns the RIPEMD-160 hash of the SHA-256 hash of the public key.
######################################################################################################

def make_miner_keys():
  
    keys    = rcrypt.make_keys()
    privkey = keys[0]
    pubkey  = keys[1]

    pkhash  = rcrypt.make_sha256_hash(pubkey)
    mdhash  = rcrypt.make_ripemd160_hash(pkhash)

    # write the keys to file with the private key as a hexadecimal string
    f = open('coinbase_keys.txt', 'a')
    f.write(privkey.hex())
    f.write('\n')       # newline
    f.write(pubkey)
    f.close()

    return (mdhash)


####################################################################################################
# add_transaction_fee directs the transaction fee of a transaction to the miner
# receives a transaction and mdhash which is the RIPEMD-160 hash of the SHA-256 hash of the public
# key of the miner
# returns the transaction with a vout component for the transaction fee
####################################################################################################

def add_transaction_fee(mempooltx: 'dictionary', mdhash: 'string') -> 'dictionary':

    #  Calculate the transaction fee
    fee = tx.transaction_fee(mempooltx)[1]

    # locking script
    locking_script   = stackprocessor.create_p2pkhash_locking_script() 

    mempooltx['vout'].append({
                        'value':  fee, 
                        'mdhash': mdhash,
                        'locking_script': locking_script
                      })

    return mempooltx


######################################################################################################
# make a coinbase transaction. This type of transaction includes the miner's mining reward 
# for mining a block. The function receives a public-private key tuple to denote ownership of
# the reward. Returns the coinbase transaction.
# Note for locktime less than 1000_000_000 the value is interpreted as a block height. For larger values
# it is interpreted as an UNIX time (seconds elapsed since midnight Jan. 1, 1970).
######################################################################################################

def make_coinbase_transaction(mdhash: 'string') -> 'dict':
    
    # calculate the mining reward 
    reward = mining_reward()

    # locking script
    locking_script   = stackprocessor.create_p2pkhash_locking_script() 

    # create a single coinbase transaction

    # make sure that there are enough transactions in the genesis
    # block to bootstrap the blockchain building process. A coinbase
    # transaction does not have any inputs so it's prior transaction
    # reference and vout reference are et to impossible values
    
    transactionid = rcrypt.make_id()
    tx = {}
    tx['transactionid'] = transactionid
    tx['version']  = 1
    # in bitcoin the reward cannot be claimed until a further
    # 100 blocks have been mined 
    tx['locktime'] = 100 + len(bchain.blockchain)                         
    tx['vin']  = []
    tx['vout'] = []

    tx['vin'].append({    
                      'txid': '',             # a coinbase transaction does not have any inputs
                      'vout': -1,
                      'sig':  '',
                      'pubkey': '', 
                      'unlocking_script': ''  
                })
                                    
    # create the vout element with the reward
    tx['vout'].append({
                        'value':  reward, 
                        'mdhash': mdhash,
                        'locking_script': locking_script
                      })

    return tx


###################################################################################################
# mine_block mines a candidate block.
# A candidate block is mined as follows:
#
# For the initial nonce value which is set in the candidate block, we compute the SHA256 hash 
# value of the block header and then convert it into a headecimal digest. We next convert this
# digest value into  (positive) integer.
# The block has been mined ff this value is less than the difficulty_no specified in the candidate
# block. Otherwise we increment the nonce by 1 and repeat the process until the block has been mined.
# Once the block is mined the miner adds the block to his or her blockchain and broadcasts the block
# over the Helium network to other nodes.
#  
# If this miner receives a new block from another miner while he is mining a block, he terminates
# mining his block and adds the new block that he has received to his version of the blockchain and
# re-broadcasts the received block.
#
# This function returns the mined block or False if there is an error or  block mined by some other
# miner is received.
#
###################################################################################################

def mine_block(candidate_block: 'dictionary') -> "bool":

     # start mining the block
     # warning: this is an infinite loop so we start a timer
     # to exit the loop if the block is not mined in a given period
     # of time (300 seconds)
     start = time.clock()

     while True:
         # compute a mining SHA-256 hash from the block header and the
         # current value of the nonce.
         arg = candidate_block['hash'] + str(candidate_block['nonce']) 
         mining_hash =  rcrypt.make_sha256_hash(arg)

         #pdb.set_trace()
         # express the mining hash as a hexadecimal number (base 16 number)
         mined_value = int(mining_hash, 16) 
         mined_value = 1/mined_value

         # test to determine whether the block has been mined
         if mined_value < candidate_block['difficulty_no']:
             break 

         # exit if the block is not mined in 300 seconds
         end = time.clock()
         if (end -start) > 300: 
             logging.debug("mining.py: timeout on trying to mine the block")
             return False
         
         # failed to mine the block so increment the 
         # nonce and try again
         candidate_block['nonce'] += 1

         # stop mining the block if a newly mined block is received
         if len(received_blocks) > 0: return False

     # adjust the difficulty so that blocks are mined in about two minutes
     end = time.clock()

     if (end - start) > 150:
         hconfig.TARGET = hconfig.TARGET * 2
     elif (end - start) < 90:
         hconfig.TARGET /= 2
            
       
     #############################################################  
     # block has been mined, add the block to the blockchain
     #############################################################

     if candidate_block['previousblockhash'] != bchain.blockchain[-1]['hash']:
         logging.debug("mining.py: previous block hash mismatch")
         return False

     logging.debug('mining.py: ready to add mined block to blockchain')

     ret    = bchain.addblock(candidate_block)
     if ret == False:
        logging.debug("mining.py: failed to add mined block to blockchain") 
        return False
     logging.debug('mining.py: mined block added to blockchain')
     
     # broadcast the newly mined block to other nodes
     broadcast_mined_block(candidate_block)

     # remove this blocks transactions from the mempool
     remove_mempool_transactions(candidate_block)

     return candidate_block


###################################################################################################
# remove_mempool_transactions: after a block is mined, the transactions in the block are removed
# from the mempool
######################################################################################################

def remove_mempool_transactions(block: 'dictionary'):
    for transaction in block['tx']:
        try:
            mempool.remove(transaction)  
        except:
            continue
    return True



####################################################################################################
# broadcast_mined_block function sends the newly mined block to other miners and nodes so that
# they may add this block to their blockchain. In the alternate case, if the miner receives a block
# from another miner, he adds it to his blockchain9 see below) and then re-broadcasts it to other nodes.
# In the implementation of this function, the miner has a list of IP addresses an port numbers of other
# nodes in the blockchain network. The miner delivers the block to these addresses.
####################################################################################################

def broadcast_mined_block(block): pass



########################################################################################################
# receive_mined_block maintains the received_blocks list. Firstly tests a received block for validity 
# and if the  block is invalid returns False. Next the function returns False if a received mined block is 
# already in the received blocks list or in the primary or secondary blockchains. Otherwise returns True 
# and adds the block to the received_blocks list.
#########################################################################################################

def receive_mined_block(block):

    # verify the proof of work
    if proof_of_work(block) == False:
        logging.debug("receive_mined_block: no proof of work")
        return False

    # Verify that the block is valid. Note that because of the False parameter 
    # we are not validating the value of the block's previousblockhash value
    ret = bchain.validate_block(block, False)    
    if ret == False:
        logging.debug('receive_mined_block: block is invalid')
        return False

    # validate transactions in the block
    for trans in block['tx']:
        if tx.validate_transaction(trans) == False:
            logging.debug("receive_mined_block: invalid transaction")
            return False


    # test if block is in the received_blocks list
    for blk in received_blocks:
        if blk == block: return False

    #test if block is in the primary or secondary blockchains
    if len(bchain.blockchain) > 0:
       if block == bchain.blockchain[-1]: return False          
   
    if len(bchain.blockchain) > 1:
       if block == bchain.blockchain[-2]: return False          
       
    if len(bchain.secondary_blockchain) > 0:
       if block == bchain.secondary_blockchain[-1]: return False          

    if len(bchain.secondary_blockchain) > 1:
       if block == bchain.secondary_blockchain[-2]: return False          

    # add the block to the blocks_received list
    received_blocks.append(block)
    
    return True


###################################################################################################
# proof_of_work: Proves whether a received block has in fact been mined. Retruns True or False
###################################################################################################

def proof_of_work(block):
    arg = block['hash'] + str(block['nonce']) 
    mining_hash =  rcrypt.make_sha256_hash(arg)
    mined_value = int(mining_hash, 16) 
    mined_value = 1/mined_value

    # test to determine whether the block has been mined
    if mined_value < block['difficulty_no']:
        return True

    return False


###################################################################################################
# The process_mined_blocks function processes blocks in the received_blocks list and attempts
# to add blocks to a blockchain. 
#
# Addition to the blockchain succeeds if the previous block hash of this block matches the hash
# of the block at the head of the blockchain.
#
# If this match fails, the previous block hash is compared to the hash of the block which is the
# parent of the head block. If there is a match, a new secondary chain is created with the parent
# at the head of the chain and the new block added to it. If the secondary block already exists,
# the block is attached to it's head, providing that the previoudblockhash matches.

# Finally the primary blockchain and the secondary blockchain are compared for length. The longer
# blockchain is designated as the primary blockchain and the other as the secondary blockchain.
#
# The transactions of the new block are then taken out of the mempool, if any such transactions
# exist in the pool
#
# After all of this is done, the new valid block is broadcast to other nodes in the network.
# Finally, the recipient node stops any mining that it is doing and starts mining a new block.
#
# If the above matches fail, the block is placed in an orphan block list. A match failure means
# that the parent of the orphan block does not exist at this  node in any blockchain. Then each 
# time a mined block is received and a blockchain is extended, we test whether the orphan block can
# be attached  to the head of the primary or secondary blockchain. If so, we attach to the head of
# a blockchain and remove it from the list of orphan blocks. Orphan blocks typically occur when two
# blocks are mined at about the same time or blocks are received out of order.
#
# The code in this function implements the distributed blockchain consensus algorithm which decides 
# the next block to be added to a blochain by distributed consensus, and not by some central
# authority deciding which blocks  will be added to the blockchain.
# Note: this function requires a prior block and thus the Genesis block must be in the blockchain.
#
# Note in production, this function should be implemented in a separate process or thread.
# 
####################################################################################################

def process_mined_blocks() -> 'bool':

    # process all of the blocks in the received blocks list
    for block in received_blocks:

        # attempt to add it to the primary blockchain
        if block['previousblockhash'] == bchain.blockchain[-1]["hash"]:
            bchain.blockchain.append(block)
            logging.debug('receive_mined_block: block added to primary blockchain')
            handle_orphans()

        # attempt to add it to the secondary blockchain
        elif len(bchain.secondary_blockchain) > 0 and \
            block['previousblockhash'] == bchain.secondary_blockchain[-1]['hash']:
            bchain.secondary_blockchain.append(block)
            logging.debug('receive_mined_block: block added to secondary blockchain')
            handle_orphans()
            compare_blockchains()

        # test whether the primary blockchain must be forked                
        # if the previous block hash is equal to the hash of the parent block of the
        # block at the head of the blockchain add the block as a child of the parent and
        # create a secondary blockchain. This constitutes a fork of the primary
        # blockchain        
        elif len(bchain.blockchain) >= 2 and  block['previousblockhash'] == bchain.blockchain[-2]['hash']:
            logging.debug('receive_mined_block: forking the blockchain')
            fork_blockchain(block)

        # cannot attach the block to a blockchain, place it in the orphans list
        else:
            orphan_blocks.append(block)

        # remove any block transactions from the mempool
        remove_mempool_transactions(block)

        # remove the block from the received_blocks list
        received_blocks.remove(block)


    return True


########################################################################################################
# fork_blockchain: forks the primary blockchain and creates a secondary blockchain from the primary
# blockchain and then adds the received block to the secondary block
########################################################################################################

def fork_blockchain(block: 'list') -> 'bool':
    # replace any existing secondary blockchain with a longer secondary blockchain
    if len(bchain.secondary_blockchain) > 0:
       # add transactions back into the mempool
       for trans in bchain.secondary_blockchain[-1].tx:
          for transaction in mempool:
             if trans == transaction: continue

          # add the transaction to the mempool
          mempool.append(trans)

       del bchain.secondary_blockchain[:]

    bchain.secondary_blockchain = list(bchain.blockchain[0:-1])
    bchain.secondary_blockchain.append(block)
    
    # switch the primary and secondary blockchain if required
    compare_blockchains()

    return True


#######################################################################################################
# compare_blockchains: compares the length of the primary and secondary blockchains. The longest
# blockchain is designated as the primary blockchain and the other blockchain is designated as the
# secondary blockchain
#######################################################################################################

def compare_blockchains() -> 'bool':

    if len(bchain.secondary_blockchain) > len(bchain.blockchain):
        tmp = list(bchain.blockchain)
        bchain.blockchain = list(bchain.secondary_blockchain)
        bchain.secondary_blockchain = list(tmp)

    return True



#########################################################################################################
# handle_orphans: tries to attach an orphan block to the head of the primary or secondary blockchain.
# Sometimes blocks are received out of order and cannot be attached to the primary or secondary
# blockchains. These blocks are placed in an orphans list and as new blocks are added to the primary
# or secondary blockchains, an attempt is made to add orphaned blocks to the blockchain(s)
#########################################################################################################

def handle_orphans():
    # iterate through the orphan blocks attempting to append an orphan
    # block to a blockchain
    for block in orphan_blocks:
        if block['previousblockhash'] == bchain.blockchain['hash']:
            bchain.blockchain.append(block)
            orphan_blocks.remove(block)
            # remove this blocks transactions from the mempool
            remove_mempool_transactions(block)


        elif len(bchain.secondary_blockchain) > 0 and  \
             block['previousblockhash'] == bchain.secondary_blockchain['hash']:
            bchain.secondary_blockchain.append(block)
            orphan_blocks.remove(block)
            compare_blockchains()
            # remove this blocks transactions from the mempool
            remove_mempool_transactions(block)

