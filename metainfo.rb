################################################################################
# ORM model -for the bittorrent metainfo file of a torrent. A metainfo file 
# record can be used to create a torrent file
# Note:  bencode piece_length as 'piece length'
#        name : full pathname of the torrent file to be created or updated
#copyright : k.singh
################################################################################

require 'digest'

class Metainfo < ActiveRecord::Base
       
	belongs_to  :torrent
	
	
	attr_accessible :name, :source_file,  :announce_list, :comment, :created_by, 
	                :length, :md5sum, :private, :piece_length,  :encoding,
	                :announce, :info_hash
	         
                        
  before_save    :validate_md5sum, :validate_created_by, :validate_torrent_extension
                 
	                
       
	
	# field validation
	
       	validates  :name, :presence => true 
        validates  :announce, :presence => true 
        validates  :announce, :format => { :with => /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/ } 	
        validates_length_of   :length, :minimum => 1 
        validates_length_of   :info_hash,  :minimum => 20, :maximum => 20, :message => "invalid length"

        validates  :private, :inclusion => { :in => [0,1]  }  
        validates  :piece_length, :inclusion => { :in => [32000, 64000, 128000, 256000, 512000, 1024000 ] } 
      
        
        # Validate the presence of the association 
      
        
        ########################################################################
        # validate_info_hash
        ########################################################################
        
        def  validate_info_hash
            
            
        end
        
        
         
               
         #######################################################################
         # validate_source_file_length 
         #######################################################################
         
         def validate_source_file_length 
             
                 if length == 0 
                         errors.add(:length, 'source file is empty')
                         return false
                 end
                 
                 return true
         end
         
        
         #######################################################################
         # validate_torrent_path: verifies that the torrent file 
         # directory path specified is valid
         #######################################################################
         
         def  validate_torrent_path
         
         	 file_path = File.dirname(name)
         	         	 
         	 return true if File.directory?(file_path)
         	 
         	 errors.add(:name, 'the directory path is invalid')
         	         	 
         	 return true          
         
       end
         
         
         
         ########################################################################
         # validate_torrent_filename: verifies that the torrent file 
         # name exists
         ########################################################################
         
         def  validate_torrent_filename
         
         	 file_name = File.basename(name)
         	 
        	 
         	 return true if !file_name.blank?
         	 errors.add(:name,  'torrent file name not specified')
         	 
         	 return false 
         	 
         end
                  
         
         #######################################################################
         # validate_torrent_extension: validates that the torrent file 
         # has the extension .torrent
         ########################################################################
         
         def  validate_torrent_extension
         
         	 ext  = File.extname(name)
        	 
         	 return true if ext == '.torrent'
         	 errors.add(:name, 'torrent file must have a .torrent extension')  
         	 
         	 return false 
         	 
         end
         
         
         #######################################################################
         # validate_torrent_file_exists: before an update - verifies that the
         # torrent file exists
         #######################################################################
         
         def validate_torrent_file_exists
                
                 return true if File.exists?(name)
                 errors.add(:name, 'torrent file does not exist')
                 return false
                 
         end
          
         #######################################################################
         # validate_created_by
         #######################################################################
         
         def validate_created_by
         
                 logger.info "CREATED BY : #{created_by}"
                 return true if !created_by.blank?
         	       errors.add( :created_by,  'author not specified')
         	
                 false
         end
         
        
          ######################################################################
          # validate_md5sum
          # The checksum may not exist when torrent files are imported
          ######################################################################
          
          def validate_md5sum 
            
                  # this is the hex value of the 16 byte digest
                  return true  if md5sum.size == 32  || md5sum.size == 0
               	  errors.add( :md5sum,  'invalid MD5 checksum')
                  false
          end
         
          
          ######################################################################
          #validate_sha1
          ######################################################################
          
          def validate_sha1 
            
                  # Each file piece has a 20 byte SHA1 checksum
                  
                  return true  if pieces.size >  0 && pieces.size%20 == 0
               	  errors.add( :pieces,  'invalid SHA1 checksum')
                  false
          end
          
            
        ########################################################################
        # validate the announce list string
        # announce list is a space separated string of IP Addresses
        ########################################################################
        
        def validate_announce_list
        	
        	return true if announce_list.blank?
        	
        	announce = announce_list.split 
        	if announce.class != Array
        	        errors.add( :announce_list,  'invalid announce list')
        	        false
        	end
        	
        	announce.each do |an|
                     if an.class != String
                             errors.add( :announce_list,  'wrong format')
                             false
                     end
        		
        	  ret = (an =~  /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/) 
        	  if ret == nil
        	              errors.add( :announce_list,  'invalid IP address')
                        return false
        	  end
        	  
          end  # end of do block
        
                 return true
         end
        
         
          
 
       
         #######################################################################
         # encode :  bencodes a source file  into a bittorrent file
         #           sets the SHA1 hash for the info dictionary
         #           returns false if there is an error otherwise returns true
         # receives the source file name and the torrent file name 
         # the filename of the bittorrent file to be created is in the name
         # parameter
         #######################################################################
         
         
         def  encode(src = source_file, torrent_file = name )
           
             if src.blank?
                 logger.info "source file for encoding not secified"
                 return false
             end
             
             logger.info "Enter bEncoder - source file = #{src}"             	       	 
         	 
                 # test that the source file exists
                 logger.info "source file:  #{ src}"

                 if  src.blank? || !FileTest.exist?(src)
                     logger.info "source file:  #{ src} does not exist - working dir = #{Dir.pwd }"
         	           errors.add(:source_file, "source file doe not exist or has zero size")
                     return false
                 end
         	 
                 
          	 ############################################
          	 # makes a SHA1 string for the source file
         	   ############################################
         	 
         	   sha1_str = make_sha1_hashes_for_pieces(src)
         	 
         	   if sha1_str == false
         	       logger.info "SHA1 Pieces Checksum error"
         	          errors.add(:pieces, 'SHA1 checksum error')
         	          return false
         	   end

         	   
             ########################################
             # set the MD5 hash for the source file         	 
             ########################################
                 
             logger.info "Set MD5 of source file "
             self.md5sum = set_md5sum(src)
                 
             if self.md5sum.length != 32
                     logger.info "MD5 checksum error"
                     errors.add(:md5sum, 'MD5 checksum error')
                     return false
             end
             
             
             ##############################
             # set the length attribute
             ##############################
                 
             len = File.size(src)
             
             if len == 0
                     logger.info "source file has zero length"
                     errors.add(:length, 'souce file has zero length')
                     return false
             end
               
             self.length = len
                 
             File.open(torrent_file, 'w')  do |f|
         	         
             logger.info "Enter block to create bittorrent file "
             
             # start the dictionary
             
             f  << 'd'
                     
         	 	 # bencode announce 
         	 	 f << '8:' 
         	 	 f << 'announce'
         	 	 f << announce.length.to_s << ':'
         	 	 f << announce
         	 	         	 	 
         	 	 #bencode announce-list
         	 	 if !announce_list.blank?
         	 	     f << 'l'
         	 	     f << '13:'
         	 	     f << 'announce-list'
         	 	     announce_list.split.each  do |sub|
         	 	             f << sub.length.to_s  << ":"
         	 	             f << sub
         	 	     end
         	             f << 'e'
         	    end
         	 	     
         	         #bencode comment
         	 	 
         	         if !comment.blank? 
         	            f << '7:' 
         	            f << 'comment'
         	            f << comment.size.to_s << ':'
         	            f << comment
         	         end
         	 	          	             
         	              
         	         #bencode created by
         	 	 
         	         if !created_by.blank?
         	            f << '10:' 
         	            f << 'created by'  
         	            f << created_by.size.to_s << ':' 
         	            f << created_by
         	         end
         	         
         	         #bencode encoding
         	 	 
         	         if !encoding.blank?
         	            f << '8:' 
         	            f << 'encoding'
         	            f << encoding.size.to_s << ':'
         	            f << encoding
         	         end
         	         
         	                	         
         	         #=====================================================
         	         # info dictionary for the single file case
         	         # info hash - key,value pairs
         	         # keys must be in lexicographic order
         	         #=====================================================

         	         f <<  'd'
         	         
         	         
         	         # do not encode name field - it is for internal use only
         	         
         	         # bencode length of file
         	                	        
         	         sz = File.size(src)
         	            if sz == 0
         	                    errors.add(:length, 'source file is empty')
         	                    return false
         	            end
         	            
         	         f << "6:" << 'length'
         	         f << 'i' << sz.to_s << 'e'          
         	                	                	         
         	         #bencode the MD5Sum
         	         f << "6:"
         	         f << 'md5sum'
         	         f << self.md5sum.size.to_s <<   ':' << md5sum  
         	             	 
         	                 	          
         	         # bencode the piece length - mandatory key
         	         f << "12:" << 'piece length'
         	         f << 'i' << piece_length.to_s << 'e'   
         	         
         	         
         	         #bencode pieces - mandatory
         	         # concatenated string of 20 byte SHA1 values
         	         
         	         sha1_cat = ''
         	         sha1_str.split.each do  |piece|
         	                 sha1_cat << piece
         	                 logger.info "concatnated #{piece} to SHA1 string"
         	         end
         	                  	         
         	         f <<  "6:"  << 'pieces'
         	         f <<  sha1_cat.size.to_s << ':'
         	         f <<  sha1_cat
         	                	         
         	         logger.info "no. of SHA1 concatenated pieces: #{sha1_cat.size.to_s}"
         	         
         	         f << 'e'  # info dictionary delimiter
         	 	 
         	 	       f << 'e'  # close the outer dictionary
         	 	       
         
         	 	 #=====================================================
         	 	 # end single file info dictionary
         	 	 #=====================================================
         
                 
                 logger.info "Encode function success"
         	 	 
        	 	 
         end  # end of do block
         
     	 
         	 	 
         	 	 #################################
         	 	 # set the info_hash
         	 	 #################################
         	 	 
             info_hash = compute_info_dictionary_sha1_hash(torrent_file)   	 	 
         	 	 
             logger.info "Info hash computed after encoding file = #{info_hash}  "
                     
             self.info_hash =  info_hash
                 
             if self.info_hash.blank?  ||  self.info_hash.size != 40
                 logger.info "info hash not created by encode "
                 return false
             end
                  
         	 
         	 return true
         	      	          	 
         end
         
         
                     
      
         ##########################################################################
         # make_sha1_hashes-for-pieces: This method computes the SHA1 value for
         # each piece of the source file and creates a string of SHA1 values: "xyz".
         # Called by the encode function only
         # Receives the source file pathname
         # Returns the concatenated SHA1 Hashes or false if there is an error
         ##########################################################################
         
         
         def make_sha1_hashes_for_pieces(source_file)
         
                                 
                sha1sum = Digest::SHA1.new()
                pieces = ""
                       
                logger.info "Enter set_sha1_string. Piece length=  " + piece_length.to_s
                
                File.open(source_file, 'r')  do  |f|
                	                	
                	while piece = f.read(piece_length) 
                		sha1sum << piece
                	        sha1_piece = sha1sum.hexdigest.to_s
                	        logger.info "Piece size = "+ sha1_piece.size.to_s
                	        return false if sha1_piece.size != 40
                	         
                	        pieces << sha1_piece
                	        
                	        logger.info "SHA1 piece = " + sha1_piece.to_s
                	end
                	
              end  # end of do block
                              	 	 
                return false if pieces.size == 0
                len = pieces.size
                
                # SHA1 piece is in hexadecimal
                return false if pieces.size%40 != 0
         	               
          
                pieces
         end
                
   
         ########################################################################
         # set md5sum - sets the MD5sum of a source  file
         # Called only by the encode method 
         # returns the MD5sum  or false
         ########################################################################
         
         def set_md5sum(source_file)
         	
                logger.info "Enter set_md5sum" 
                
              	sum = Digest::MD5.new()
                f = File.open(source_file, 'r')
           
                f.each_line do |line|
                        sum << line
                end
         	             
                md5sum = sum.hexdigest.to_s
             
                logger.info "MD5 = " + md5sum
                logger.info "MD5 size = " + md5sum.size.to_s
         	
                f.close
                 
              	return false if md5sum.size.to_s != '32' 
 
              	self.md5sum = md5sum 
         	
                return md5sum
         	         	 
         end     
     
         
     
         ########################################################################
         # decode : reads and decodes a bittorrent file and creates a 
         # ruby hash corresponding to the file
         # returns the torrent hash or false if the hash cannot be created
         # receives the file name of a torrent file 
         ########################################################################
         
         
         def  decode(bittorrent_file = name)
         
                 logger.info "Enter bittorrent file decoder"
                 
                 # test that the bittorrent file exists
                      	 
                 if !File.exist?(bittorrent_file) || !File.size(bittorrent_file)
                         errors.add(:name, 'bittorrent file does not exist or is empty')
                         logger.info(" bittorrent file does not exist")
                         return false
                 end
                 
                 logger.info "Ready to process file"
                 
                 
                 ###########################################
                 # open the file and start reading tokens
                 ###########################################
                 
                 File.open(bittorrent_file, 'r')   do  |f|
            
                     
                         
                 ######################################
                 # Intialize Torrent File Decode Loop
                 ######################################

                 
                 @torrent_hash    = {}         # hash to be created
                 
                 #  the type stack pushes a "l" token on the stack when a 
                 #  list starts and a "d" token wnen a ditionary starts
                 #  it then pops elements when a list or dictionary ends
                 #  the stack identifies nested lists and dictionaries
                 
                 @type_stack      =  []     
              
                 # hash elements - will be built incrementally for lists
                 # and dictionaries
                 # key and hash elements for @torrent_hash
                 
                 @key      =  ""
                 @value    =  ""
             
                 # to create the info dictionary
               
                 @info_hash  = {}
                 @dict_key   = ""
                 @dict_value = ""
               
                 
                 
                 ###############################
                 # The first char must be a 'd'
                 # for a torrent file
                 ################################
                 
                 while !f.eof?
                         
                    c = f.readchar
                    if c!= 'd'
                        logger.info "Invalid First Char in file"
                        return false
                    end
                    break
                
                end
                
                         
                
                 ################################
                 # read torrent file until EOF
                 ################################
                 
                 while !f.eof?
                         
                    c = f.readchar
                    token = ""                        
                    
                    ############################
                    # a string token identified
                    ############################
                    
                    if c =~ /\d/
                            slen = c       
                            token = get_string_token(f,slen)
                            
                            return false if token == false
                   
                            
                    #############################
                    # Integer Token Identified
                    #############################
                    
                     elsif c ==  'i'
                                   
                            token = get_integer_token(f)
                            
                            return false if token == false
                    
                           
                            
                    #########################
                    # List Token Identified
                    #########################
                    
                     elsif c ==  'l'
                           
                         # There is an error if the @key is not empty and the @value
                         # is  blank. The hash key has not value
                         
                         if !@key.blank?  && @value.blank?
                             logger.info "Invalid list start - key for list not present"
                             return false
                         end
                         
                         # push the list identifier on the type stack
                         @type_stack < "l"
                             
                         # insert opening bracket
                         @value << "["
                                                      
                         # continue extracting tokens whixh will be 
                         # list elements 
                         next                                                  
                    
                         


         
                    ##########################################
                    # Dictionary Token Identified. A torrent 
                    # file can have only one enclosed info 
                    # dictionary
                    ##########################################
                    
                    elsif c ==  'd'
                           
                        # There is an error if the @key is not empty and @value is 
                        #  blank. The hash key must have a value
                         
                        if (!@key.blank?  && @value.blank?) || (@key.blank? && !@value.blank?  )
                             logger.info "Invalid dictionary start - key, value error"
                             return false
                        end
                        
                                                 
                                                
                        # push the dictionary identifier on the type stack
                        @type_stack << "d"
                        logger.info "dictionary id pushed on stack"     
                        # insert opening brace
                        @value << "{"
                                                      
                        # continue extracting tokens whixh will be 
                        # list elements 
                        next                                                  
                
        
                                    
                    ###############################################
                    # an e token is captured. It signals
                    # the end of a list of a dictionary. Pop the
                    # type stack to determine the data structure
                    ##############################################
                    
                    elsif c == 'e' &&  @type_stack.last == 'l'
                           
                          # close the list
                          @value << "]"
                          # pop value of stack
                          @type_stack.delete_at(-1)
                        
                          # create a hash value
                          @torrent_hash[@key.to_sym] = @value
                      
                          # clear the key value buffers
                          @key = ''; @value = '';        
                       
                          next
                      
                   
                    
                    
                    ##################################
                    # an 'e' token for a dictionary 
                    # is captured
                    ##################################
                     
                    elsif c ==  'e'  &&  @type_stack.last == 'd'
                          
                        @torrent_hash[:info] = @info_hash
                        
                        # pop value of stack
                        @type_stack.delete_at(-1)
                        logger.info "dictionary id popped off stack"
                          
                        # clear the key value buffers
                        @key = ''; @value = '';
                        @info_hash = {}
                       
                        next
                       
                   
                    
                    
                end   # end of outer if block
                

                    #########################################
                    # Incrementally Build The  Torrent Hash
                    #########################################

                    if @type_stack.size > 0  && @type_stack.last == "d" 
                        make_dictionary_hash(token)
                    else    
                        make_torrent_hash(token)    
                    end             
                                                            
                end  # end of while block
             
                
                
                
        end  # end of file  block
      
        
        
        #########################################################
        # there is a syntax error if the type stack is not clear
        #########################################################
        
        if @type_stack.size > 0
            logger.info "Type Stack closure error size = #{@type_stack.size.to_s} : last = #{@type_stack[-1] }"
            return false
        end
                
        if @torrent_hash == {}
            logger.info "decoded torrent hash is empty"
            return false 
        end
        
        logger.info "Return from Decoder : Torrent Hash : #{@torrent_hash.to_json}"
       
        
        return @torrent_hash
           
        
    end  # end of decoder method
         
    
    
     
      
      #########################################################################
      # get_torrent_file_info_hash : receives a torrent file
      # returns the Ruby info hash or  false if there is an error
      # called by the encode method
      #########################################################################
      
      
      def  get_torrent_file_info_hash(bittorrent_file = name)
          
          # decode the bittorrent file.
          # create the Ruby hash of the torrent file
          
          torrent_hash = decode(bittorrent_file)  
          
          return false if torrent_hash == false
          
          return torrent_hash[:info]
          
          
      end
      
      
      ##########################################################################
      # compute_info_dictionary_sha1_hash:  This computes the 20 byte URL 
      # encoded value of the info directory
      # Receives the torrent file
      # Returns false or the SHA1 value of the info dictionary in the torrent
      # file 
      ##########################################################################
      
      
      def  compute_info_dictionary_sha1_hash(bittorrent_file = name)
          
          # create the Ruby hash of the torrent file
          
            torrent_hash = decode(bittorrent_file)  
            return false if torrent_hash == false
          
            
            # extract the info dictionary
            
            info_dict = torrent_hash[:info]
            
            # Construct a bencoded string from the info_dict
            bdict  = "d"
            
            info_dict.each do  |key, value|
           
                keylen = key.length.to_s
                
                
                ####################
                # bEncode the key 
                ####################
                
                bdict << keylen << ":" 
                
                key = "piece length"  if  key.to_s == "piece_length"
                bdict << key.to_s    
                
                
                ####################
                # bencode the value
                ####################
                
                if key.to_s == 'length' || key.to_s == "piece length"
                    bdict << "i" <<  value << "e"
                else
                    bdict << value.length.to_s << ":" << value
                end
                
                
            end  # end of do block
            
            # close the dictionary
            
            bdict << "e"
            
            
            # compute the SHA1 Hash of the bencoded string
            
            sha1_hash = Digest::SHA1.new()
            sha1_hash  << bdict
            sha1_hash = sha1_hash.hexdigest.to_s
            
            logger.info "Extracted info dictionary = #{info_dict.to_json} "
            logger.info "info dictionary bencoded string = #{bdict.to_json} "
            logger.info "info dictionary SHA1 HASH = #{sha1_hash} "
            
            return sha1_hash
      end
             
      
                 
    
         #########################
         #  private
         #########################
         
         private
        
         
         ########################################################################
         # get_string_token : extracts a string token
         # called by the decode method
         # receives a file descriptor to the torrent file
         # and the first digit of of the length of the token
         # returns the token or false if there is an error
         ########################################################################
         
         def  get_string_token(f, slen)
            
                 
             # read the bittorrent file
             
                while !f.eof?
                      
                     c = f.readchar
                          
                     # loop reading the length tokens
                     if c =~ /\d/
                          slen << c
                          next
                      elsif c != ':'
                          logger.info "Invalid string token element"
                          f.close   
                          return false
                      end     
                           
                             
                      # a ':" has been read in - now get the actual string token
                          
                     len = slen.to_i 
                          
                     if len == 0
                           f.close
                           logger.info "error length of string is 0"
                           return false
                     end        
                     
                     begin             
                             token = f.read(len)
                     rescue
                             logger.info "Exception : attempt to read beyond EOF"  
                             f.close
                             return false
                     end        
                          
                     logger.info "extracted token: #{token}"  
                     logger.info "length of token : #{len}"
                      
                     # return the string token
                      return token
                      
              end #end of while loop
                             
                            
              # should not come here
         
              return false
              
              
          end  # end of get_string_token method
              
        
        
            
         ########################################################################
         # get_integer_token: extracts a integer token from a bittirrent file
         # receives a file descriptor to the torrent file
         # returns the token or false if there is an error
         ########################################################################
         
         def  get_integer_token(f)
            
                 token = ''
            
                 # read the bittorrent file
                 while !f.eof    
                                 
                         c = f.readchar         
                         
                         # loop collecting integer elements
                         if c != 'e'
                                 token << c        
                                 next
                         end
                           
                         # token created - validate
                         logger.info "the integer token is : #{token}"
                         
                         ret = (token =~/^[+-]?\d+$/)
                         
                         return false if ret == nil
                         
                         # string of digits cannot be preceded by a 0 element
                         
                         return false if token.length > 1 && token[0] == '0'
                         
                         break
                                 
                                 
                 end  # end of while loop                 
                                         
                 
                 return token
                 
         end  #  end of get_integer_token
         
         
            
       
         
         ########################################################################
         # make_torrent_hash : Incrementally Builds The Token Hash Structure.
         # Called by decode
         # Recieves a string or integer token. The token can be nested inside a
         # list of dictionary
         # outputs a hash element: @torrent_hash[@key.to_sym] = @value
         ########################################################################
         
         
         def  make_torrent_hash(token)
            
             
                          
             #########################################
             # If @key is blank set the token to the
             # hash key. Otherwise the token is a 
             # key value
             ########################################
             
             if @key.blank?
                 
                  # key token cannot contain a space
                  #substitute a underscore. bencoding
                  # has no keys with underscores
                         
                  token = token.gsub(' ', '_' )
                  @key << token
                 
                  # case where the value is inside a list
                  # add the  token to @value and return
                  
              elsif  @type_stack.size > 0  && @type_stack[-1] == 'l'
                   
                  @value  << ','  << token 
                  return
                         
                                               
              else         
                   @value << token
              end
                 
                 
                 ##################################################
                 # if the key and value are filled then add the
                 # pair to the hash
                 ##################################################
                      
                 if !@key.blank? &&  !@value.blank?
                              
                        # create a hash value
                        @torrent_hash[@key.to_sym] = @value
                      
                        logger.info "hash key created"
                        
                        # clear the key value buffers
                        
                        @key = ''; @value = '';        
                      
                      end
                 
                                           
                 
              end  #  end of method
         
              
         ########################################################################
         # make_dictionary_hash : Incrementally Builds the hash for a dictionary
         # called by make_torrent_hash
         # Recieves a string or integer token. The token can be nested inside a
         # list of dictionary
         # outputs a hash element: @torrent_hash[@key.to_sym] = @value
         ########################################################################
         
         
         def  make_dictionary_hash(token)
            
                                          
             #########################################
             # If the dict_key is 0  the token is a
             # hash key. Otherwise the token is a 
             # key value
             ########################################
             
                 if @dict_key.blank?
                 
                         # key token cannot contain a space
                         #substitute a underscore. bencoding
                         # has no keys with underscores
                         
                         token = token.gsub(' ', '_' )
                         @dict_key << token
                                                                    
                  else         
                      @dict_value << token
                  end
                 
                 
                 ##################################################
                 # if the key and value are filled then add the
                 # pair to the hash
                 ##################################################
                      
                 if !@dict_key.blank? &&  !@dict_value.blank?
                                           
                        # create a hash value
                        @info_hash[@dict_key.to_sym] = @dict_value
                      
                        # clear the key value buffers
                        
                        @dict_key = ''; @dict_value = '';        
                      
                      end
                 
                                           
                 
              end  #  end of method
              
              
      
         
end  # class end


