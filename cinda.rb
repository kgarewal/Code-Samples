#!/usr/lib/ruby

################################################################################
# Ruby Video On Demand Sample
# cinda : Cinda manages a set of TCP Socket peers that are downlading a file
# This is a Distributed Ruby Service implemented as a Ruby Object, it maintains
# state information for files being downloaded and coodrinates participating
# local peers. It spawns TCP sockets as required.
# 
# Named after Linda and Rinda
#
# The service runs in an infinite loop. It creates and destroys peers as needed.
#
# Heartbeat: participating peer sockets send a hearbeat periodically. If a
# hearbeat is not received. Cinda assumes that the socket as terminated 
#
# The service object is accessible through dRuby  only
# Manages the details for a file being downloaded by a set of local peers
# Manages what portions of a file have been uploaded, what portions have been 
# downloaded and which local peers are downloading which pieces
#
# Start from the command line
# copyright : k.singh
# license : GPL v. 3
################################################################################


$: <<  File.dirname(__FILE__)

require 'environment'
require 'drb'
require "socket.rb"
require "torrent_parser.rb"
require "peer.rb"
require 'digest'
require 'socket_helper.rb'
require 'bitfield.rb'


# Run the service at level 1.  processes cannot eval() remotely
# If the service is running on localhost we can use $SAFE= 0 
#$SAFE = 1

class  Cinda

    include Environment
    include DRbUndumped
    include HTTParty
    include SocketHelper
    
    
    ###########################################
    # Class Constants
    ###########################################
    
     
        
    
    ############################################################################
    #  initialize
    #  torrent file management data structure:
    #  filemap hash: 
    #                = {
    #                 :info_hash => "";     20 byte SHA1 hash of the info dictionary
    #                 :file_name =>  "",    name of file  
    #                 :file_size => 0  ,  
    #                 :piece_length = > 524288  # length of a file piece. Other piece sizes - 1 Mb, 256 KB
    #                 :pieces  =>  [],    SHA1  hashes for all pieces of the file   
    #                 :have_pieces   => [],   #example   [1, 67, 39, 24]
    #                 :missing_pieces => []
    #                 :num_pieces     => 0   # total number of pieces
    #                 :announce       => []  # Array of peers having pieces of the file  
    #           }
    #
    #  Note: have_pieces and missing_pieces are indexes into the file incrementing
    #  the index  by 1 would move the file pointer by piece_length. If we are 
    #  downloading a new file have_pieces will be an empty array and missing_pieces
    #  will be the entire index range
    # As peers report that a pice has been downloaded, Cinda updates the structure
    # Cinda also looks at the missing pieces array to advise a peer as to which
    # piece to download next
    # When beginning the download of a new file, Cinda decodes the torrent file
    # and sets the file_download structure and then creates the peers as required 
    # Cinda periodically advises the tracker of it's sstatus
    #
    # copyright k.singh
    ############################################################################
    
    
    def  initialize(torrent_file)
               
        log "cinda > initializing  service..."
             
        # open the log file
        Dir.chdir (File.dirname("__FILE__"))
        @log = File.new("../log/cinda.log", "a")
                
        
        @filemap = {}
        
        @info_hash = ""     # SHA1 info hash of the info hash dictionary
        @torrent_hash = {}  # hash of the turrent file

        
        
        ##########################################
        # sockets hash: each array element is a
        # hash:   
        #          @sockets[ object_id]  =>    
        #               { :pid => pid, 
        #                 :peer_id   => peer_id,
        #                 :type 
        #                 :info_hash
        #                 :heartbeat = "",
        #                 :dead = false
        #               }
        #          ]
        #
        #  
        ##########################################
        
        @sockets = []    # array of sockets downloading file pieces 
            
        
        
        ######################################
        # initialize the filemap structure
        ######################################
        
        initialize_filemap()
        
        
        ###################################################
        # create a scheduler thread to query the tracker
        ###################################################
        
        query_tracker()
        
        ####################################################
        # Create a server peer TCP sockets
        ####################################################
        
        create_server_peers
        
        log  "cinda > initialized"
        
        #cinda_stop
        
    end
    
    
    ############################################################################
    # initialize_filemap:  Parses  a torrent file to initialize the filemap
    # structure. The info_hash in the filemap will be used to query the Tracker
    # in order to get a list of participating peers.
    # Algorithm: 
    #  PASS 1
    # (1) scans the cache directory. For each file in the cache, it creates
    #     a ruby hash
    # (2) scans all of the info-hashes of all  files in the torrents directory.
    # (3) If the torrent hash does not exist,creates a torrent file for the
    #     cache file
    # PASS 2 
    # (1) parse the torrent file into a Ruby Hash
    #     Fill in a  filemap entry from the hash
    # (2) If the filemap entry does not exist, Cinda has an incomplete copy of this
    #     file. 
    # (3) For each such file creates a filemap structure. Files in the cache
    #     directory are presumed to be complete.
    #
    ############################################################################
    
    
    def  initialize_filemap()
    
        #################################
        # filemap Pass 1
        #################################
        
        filemap_pass_1()
        
        #################################
        # filemap Pass 2
        #################################
        
        filemap_pass_2()
        
        return
        
        
    end  # end of initialize-filemap
    
    
    
    
    ############################################################################
    # filemap_pass_1 : Pass 1 of the initialize filemap algorithm
    # Complete files are kept in the cache directory 
    # returns true or false
    ############################################################################
    
    def  filemap_pass_1
        
        log "beginning filemap algorithm pass 1"
       
         parser = BitTorrent.new
            
        ################################### 
        # read all source files in cache
        ###################################
        
        Dir.foreach("../cache")  do  |file|
        
            next if File.directory?(file)
            File.delete(file) if File.extname(file) == ".torrent"
            
            log "cache file = #{file}"
            
            # if the torrent for this file exists continue
                   
            torrent_file = File.basename(file)
            torrent_file +=  ".torrent"
            log "torrent_file = #{torrent_file}" 
            
            next if File.exists?("../torrents/torrent_file")
             
                
            # torrent for the file does not exist. create it
           
            # encode the source file
           
            log "cinda > determining IP Address to use"
            addr = get_server_address           
            
            bittorrent = {
                :source_file => file,
                :torrent_file => torrent_file,
                :piece_length  => 524288,
                :announce     =>  addr,
                :created_by   => "Ruby Vod Simulator",
                :encoding     => "bittorrent",
                :announce_list => "",
                :comment      => ""
                
            }

            
        ret = parser.encode(bittorrent)
               
        if !ret
            log  "cinda > failed to encode #{file}"
            next
        end
            
            
        end # end of dir block
        
        return true 
        
        
    end # end of filemap_pass_1

    
    
    ############################################################################
    # filemap_pass_2 : Pass 2 of the initialize filemap algorithm
    ############################################################################
    
    def  filemap_pass_2
        
        log "cinda > filemap algorithm start pass 2"
        
        # read all torrent files in the torrents directory
        
        parser = BitTorrent.new
        
        #######################################
        # Parse All Torrent Files
        #######################################
        
        Dir.foreach("../torrents")  do  |file|
        
            next if File.directory?(file)
            log "file to be parsed  #{file}"
            
            # parse into a Ruby hash 
            
            torrent_hash = parser.parse(file)
            if torrent_hash == false
                   log "cinda > cannot parse torrent file #{file}" 
                   File.delete(file)
                   next
            end
            
            ######################
            # get the info hash
            ######################
            
            info_hash  = parser.compute_info_hash(torrent_hash)

            next if info_hash == false
        
            
            #######################################
            # build a filemap entry
            #######################################
        
            total_pieces = torrent_hash[:info][:length].to_i /  torrent_hash[:info][:piece_length].to_i
            total_pieces += 1 if (torrent_hash[:info][:length].to_i %  torrent_hash[:info][:piece_length].to_i) != 0
            
             
            ######################################
            # generate the array of SHA1 pieces
            ######################################
        
            ctr = 0
            pieces = []
            while ctr <  total_pieces
                pieces  << torrent_hash[:info][:pieces][ctr,20] 
                ctr += 1
            end
        
            have_pieces    = []
            missing_pieces = [] 
    
            # if the torrent file exists in the cache directory then
            # cinda has all of the file
            
            src_file  = File.basename(file, ".torrent")
            whole_file = File.exists?("../cache/#{src_file }")?  true : false
            
                      
            
            @filemap[info_hash] =  {
                
                
                :object_id        =>  "",
                :announce         =>  torrent_hash[:announce],
                :name             =>  "", 
                :length           =>  torrent_hash[:info][:length],
                :piece_length     =>  torrent_hash[:info][:piece_length],
                :pieces           =>  pieces,        # Array of SHA1 Hashes for filepieces 
                :socket_id        =>   "",
                :socket_address   =>   "",
                :socket_port      =>    0,
                :peers            =>    0,         # participating peers [ip_address:port ...] 
                :pieces_bitfield  =>    [],        # bitfield for the pieces the peer has
                :total_pieces     => total_pieces, # total number of pieces
                :have_whole_file  => whole_file
                
            }
            

            #log "cinda > FileMap entry : #{@filemap[info_hash].to_s}  "             
            
            
            
        end  # end of Do Block
        
        
    end #  filemap pass 2
    
    
    
    ############################################################################
    # create_server_peers: creates a server peer socket. Cinda passes the
    # local host and port. 
    # A TCP Peer server Only serves files which cinda has in full.
    #
    # arguments:
    #        local host 
    #        local port
    #        cinda host
    #        cinda port 
    #        filemap element  
    #
    ############################################################################
    
    
    def  create_server_peers
        
                    
           # Test that we can fork processes
           forkable = Process.respond_to?(:fork)
           log "cinda > Processes forkable = #{forkable.to_s}"
           
           pid = fork
           
           # we will create one TCP Server and break from the loo[
           
           @filemap.each   do |key, value|            
           
               puts "filemap =  #{@filemap[key].to_json.to_s}"
               exit
               next if !@filemap[:key][:have_whole_file]
                 
                ####################################
                # create child process and detach 
                ###################################
          
                
                if !pid
                    
                    #peer =  Peer.new(filemap.)
                    begin
                    #     peer.start
                   
                    rescue => ex
                         log "forked peer socket constructor failed : #{ex.message}"
                         exit -1
                    end
                    
                    break
                end
          
           
               #Process.detach(pid)      # zombie processes if detached
                                
           
       end # end do block
        
       
       log "cinda > returning from peer constructor"
        
    end  # end of create_peers
    
    
    
    
    
    ############################################################################
    # ping cinda
    ############################################################################
    
    def  ping
           'pong'
    end   
    
    
    ############################################################################ 
    # register : callback function invoked by a peer through dRuby to 
    # set peer socket information
    # register is only called when the peer has established a connection 
    ############################################################################

    def  register(sock)

        log  "cinda > registering the peer"
        
        objectid = sock[:object_id]

        if objectid == nil
            log "cinda > register did not get an object id"
            exit -1
        end
        
        if @sockets[objectid] == nil
            log "cinda > register - object id is unknown"
            exit -1
        end
        
       
        @sockets[object_id][:peer_id] = sock[:peer_id] if sock[:peer_id]
    
        
        
    end  # end of register
    
    
    
    
    ############################################################################
    # cinda_stop  : stop the service
    ############################################################################
    
    def cinda_stop
        
        @sockets.each  do |s|
           # TODO send a message to each socket to close the connection
            # Hack
            
        end
            
            
   end
    

################################################################################
# heartbeat: Each peer socket  sends cinda a hearbeat message.If the messeage

################################################################################


def  heartbeat(objectid)
    return
    log "\nenter cinda heartbeat"
    
    if objectid == nil
        log "cinda heartbeat  did not get an object id"
        return 
    end
        
    if @sockets[objectid] == nil
        log "cinda heartbeat - object id is unknown"
        return
    end    
    
        #################################################
        # if a hearbeat is not received within a
        # certain interval, the socket is presumed dead
        #################################################
        
        if (Time.now  - @sockets[objectid][:heartbeat]) > ALIVE
                log "socket has died : object_id = #{ objectid.to_s } "
                @sockets[objectid][:dead] = true
        end
        
        log "exit cinda heartbeat\n"

        
end  # end of hertbeat method


################################################################################
# query_tracker :  creates a thread that queries the tracker periodically 
# to get a list of peers that are participating in uploading and downloading 
# the file
# Uses the gem HTTParty to encapsulate the HTTP protocol
################################################################################

def  query_tracker

           pid = fork
                      
           ####################################
           # create child process and detach 
           ###################################
          
           if !pid
               
               # child thread processsing loop
               
               while true
                   
                   log "\ninside query_tracker thread.... sleeping "
                   sleep CINDA_ALIVE
                   # HTTP GET request to the tracker
                   response = HTTParty.get("http://localhost:3000")
                   log "\ntracker response = " + "#{response.to_s}"
                   
                   end  # end of loop
               
           end  # end thread block
          
           
           Process.detach(pid)      # prevent zombie processes


   
end  # end of query tracker



end  # end of  Cinda


################################################################################
# Start The Cinda Distributed Object From The Command Line
# receives a torrent file name. Torrent must exist in the torrents directory
################################################################################

if ARGV.size  != 1
    puts "usage :  cinda  <torrent file>" 
    exit -1
end


###################################################
# start The Cinda service on a well-known port on
# the local host
# Receives a torrent file name
###################################################


DRb.start_service("druby://127.0.0.1:9876", Cinda.new(ARGV[0]))
DRb.thread.join





