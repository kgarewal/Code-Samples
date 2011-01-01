   require 'rubygems'
   require 'pg'
   require 'net/imap'
   require 'logger'

   require 'drb'
 
   $SAFE = 1

   
   
  ########################################################################
  # makeimap_server:  Distributed Ruby Server To make IMAP accounts
  #                   using dRb Ruby lib 
  #  Provides authorized remote clients access to IMAP and Sendmail 
  #  Services
  # creates an imap account for the user along with
  # authentication credentials in postgresql
  # parameters:  user, password, the imap account name, 
  # the term of the account in days
  # quota is received in Bytes
  # debug flag
  # Routine logs all account activity
  # NOTE: Sanitized command line parameters must be passed
  # Uses raw postgreSQL and IMAP connections 
  # Server bootup code at the end of file
  ########################################################################

  
  class MakeImapServer


     def   make_imap_account( membr, pass, memb_imap, trm, quota,  debug)
  
   
     @member =  membr
     @passwd =  pass
     @term = trm
     @member_imap  = memb_imap


    ########################
    #  Log Activity
    #######################

    @flogger =  Logger.new("/var/log/cryptmk.log", 20, 10000*1024)
    @flogger.datetime_format = "%Y.%m.%d : %H:%M:%S"

    if debug == 1
           @flogger.info("#{@member}: Server Entry")

    end   

      

     @err = "" 



   
    ########################################################
    # Make A Connection To The PostgresSQL IMAP Database
    #  (host, port, options, tty, database, user, password)
    ########################################################


   conn = PGconn.connect('localhost',5432, "", "", "********", '********','************')

   if conn.nil? == true

    @flogger.error("Failed to open the postgres  database on localhost for *********")
    @err = "Error : Failed To Open Authentication System"
    @flogger.close()
    return

   end

    if debug
           @flogger.info("#{@member}: Postgres database opened")
    end   



   ##########################################
   # Test That The User Does Not Exist In 
   # the cryptbin Table
   ##########################################
 

   begin

       res = conn.query("SELECT * FROM crypticbox_users WHERE user_uid=$1", [@member])
   rescue

            @flogger.error("#{@member}: Authentication Exception Thrown")
            @flogger.close
	    @err = "Warning : Authentication Exception"
            return @err
   end


   ctr = 0
   res.each  do
       ctr += 1
   end

   if ctr > 0
            if ctr == 1
                @flogger.warn("#{@member}: Authentication Credentials already exist for this mail account")
            elsif ctr > 0
                @flogger.error("#{@member}: MAJOR ERROR DUPLICATE AUTHENTICATION CREDENTIALS")
            end            


            @flogger.close
	    @err = "A Mail Account Already Exists For This User. Try A New Mail Address"
            
            res.clear()
            conn.finish()
            return @err
   end



    if debug
           @flogger.info("#{@member}: Postgres database successfully queried")
    end   

    res.clear()


   #######################################################
   # Create A New User
   # exec always returns an exception even if the 
   # insert is done
   ######################################################



#   begin

#       res = conn.exec("INSERT INTO crypticbox_users(user_uid, user_pass, user_soft_expiration_date, user_hard_expiration_date,active ) VALUES($1, $2, $3, $4, $5)", [@member, @passwd, (Time.now()+365).to_i, (Time.now()+365).to_i, 1])
#   rescue
#        @flogger.error("Exception ::Failed To Create authentication credentials - VALUES:  #{@member}: #{@passwd}   #{@member_imap}")
#        @err = "Error: Failed To Create Authentication Credentials For Mail Account"
#        @flogger.close       
#        return @err
#   end
#        if res.cmd_status() == 1    
#           @flogger.info("#{@member}: Authentication Credentials Created")
#        else
#           @flogger.error("Failed To Create authentication credentials - VALUES:  #{@member}: #{@passwd}   #{@member_imap}")
#           @err = " Verification Failure :   Mail Authentication Credentials Not Verified "
#           conn.finish()
#           return @err
#  end


  begin

     res = conn.exec("INSERT INTO crypticbox_users(user_uid, user_pass, user_soft_expiration_date, user_hard_expiration_date,active ) VALUES($1, $2, $3, $4, $5)", [@member, @passwd, (Time.now() + (@term * (3600*24)) ).to_i, (Time.now() +  (@term * (3600*24) + (3600*24*1) )  ).to_i, 1])

  rescue

    # restart the connection

   if conn.status() == CONNECTION_BAD

        conn = PGconn.connect('localhost',5432, "", "", "***********", '**********','***********')

        if conn.nil? == true

           @flogger.error("FAILED TO REOPEN POSTGRES DATABASE AFTER INSERT RECORD EXCEPTION CLOSURE")
           @err = "Error : Failed To Re-Open Authentication System"
           @flogger.close()
           return

        end

        if debug
                @flogger.warn("#{@member}: Postgres database Reopened After Exception closure")
        end   
    
    end  # end of Connection_Bad block


  end  # end of exception block



  
#############################################
#  Test That The Member Has Been Created
#############################################

   begin

       res = conn.query("SELECT * FROM crypticbox_users WHERE user_uid=$1", [@member])
   rescue

            @flogger.error("#{@member}: Horde user not created - Test Authentication Exception Thrown")
            @flogger.close
	    @err = "Warning : Verify Authentication Exception"
            return @err
   end


   ctr = 0   
   res.each{ ctr += 1}

   if ctr == 0
       @err = "Unable To Create Member : We will set up your account manually"
       @flogger.error("MEMBER ACCOUNT NOT CREATED IN POSTGRES")
       conn.finish()
       return
   end
  

    if debug
           @flogger.info("#{@member}: new mail crypticbox_users record created")
    end   
  

  #########################
  # close The connection
  #########################


   conn.flush()
   conn.finish()



  ######################################
  # create an IMAP account 
  #####################################

  begin

      imap = Net::IMAP::new('localhost', 143)

  rescue

     @flogger.error("#{@member}: IMAP Constructor Failed")
     @flogger.close()
     err = "Error : IMAP Constructor Failed"
     return

  end


  if debug
           @flogger.info("#{@member}: IMAP Constructor Created")
  end




  ####################
  # IMAP Login
  ####################


  begin

      imap.login( '***********', '**********')

  rescue

     @flogger.error("#{@member}: IMAP login By User ********** failed")
     @flogger.close()
     @err = "Error : Cannot Login Into Mail Server" 
     return

  end


    if debug
           @flogger.info("#{@member}: IMAP Admin Logged Into IMAP Account")
    end   


  ################################################
  #  Create A  IMAP Account
  ################################################

  begin

     imap.create("#{@member_imap}")

  rescue
     imap.logout

     @flogger.error("#{@member_imap}: FAILED - IMAP Account Creation")
     @err = "Error : Cannot Create IMAP Mail Account"           
 
     @flogger.close()
     return

  end



   if debug
           @flogger.info("#{@member_imap}: IMAP Account Created")
   end   




  ####################################
  #  Set ACLs for mail account
  ####################################


  begin

         imap.setacl("#{@member_imap}", "*************", "lrswipcda")

  rescue
         imap.logout
         @flogger.error("#{@member}: acl could not be set")
         @flogger.close()
         return

  end


  @flogger.info("#{@member_imap} :  #{@member_imap} : IMap ACL set")



  ##########################################
  #  Set quota for the mailbox
  ##########################################


  begin

         imap.setquota("#{@member_imap}", quota)
       
  rescue
         imap.logout
         @flogger.error("#{@member}: quota could not be set")
         @flogger.close()
         return
  end


  @flogger.info("#{@member}: #{@member_imap}  Mailbox Quota set")


  

  #####################
  # Logout of IMAP
  #####################


  imap.logout

  if debug
           @flogger.info("#{@member}: Logged Out Of IMAP Account")
  end   





  ###########################################################
  # Regenerate The sendmail MailerTable For A New Domain
  ###########################################################


  if debug
           @flogger.info("#{@member}: setting sendmail mailertable")
  end




  Dir.chdir("/etc/mail/")  



  ###########################
  # extract the domain name
  ###########################

  domarray = @member.split('@')  



  ########################
  # test for only one  @
  ########################

  if domarray.size != 2
       @flogger.error("#{@member}: ERROR:  invalid domain : (invalid No Of @ Symbols : sendmail:mailertable/relaytable not set")
       @flogger.close()
       @err = " MailerTable/RelayTable will be setup manually "
       return
  end



  ######################################################################  
  # If the domain already exists in the mailertable do not do anything
  ######################################################################

  mailer_table_flag = false

  if domarray[1] == "crypticbox.com"
      @flogger.info("#{@member}  : Sendmail Mailer Table not changed : domain crypticbox.com found")
      mailer_table_flag = true
  end



  if domarray[1] == "biosmail.net"
      @flogger.info("#{@member}  : Sendmail Mailer Table not changed : domain biosmail.net found")
      mailer_table_flag = true
  end


  if domarray[1] == "greenleafmail.com"
      @flogger.info("#{@member}  : Sendmail Mailer Table  Not  changed :  domain greenleafmail.com found")
      mailer_table_flag = true
  end


  
  if mailer_table_flag == false

       mltable =  IO.readlines("/etc/mail/mailertable")
 
       mltable.each  do  |val|

           if val.index("#{domarray[1]}") != nil
                  @flogger.info("#{@member}  : Senddmail Mailer Table  not changed : domain #{domarray[1]}  exists in Mailer Table")
                 
                  mailer_table_flag = true
               
           end      

       end  # end of loop


    ###############################################
    # Regenerate The Mailertable for a new domain
    ###############################################

      if mailer_table_flag == false 

           f1 = File.new("/etc/mail/mailertable", "a+")
           f1.flock(File::LOCK_EX)
           f1.puts("#{domarray[1]}  cyrusv2:/var/imap/socket/lmtp")
           f1.flock(File::LOCK_UN)

           @flogger.info("#{@member}: Sendmail Mailer Table  entry added for  domain: #{domarray[1]}")

           f1.close()


           `makemap hash /etc/mail/mailertable.db < /etc/mail/mailertable `
  
            @flogger.info("#{@member}: Sendmail Makemap called for Mailertable makemap called to add domain: #{domarray[1]}")

            @flogger.info("#{@member} : Mailertable rebuilt")
   

         end #  end of mailer_table == false flag


     end    #  end of mailer_table_flag block



  ##############################################
  # Add The Domain To The Relay-Domains File
  ##############################################


  relay_table_flag = false

  relaytable =  IO.readlines("/etc/mail/relay-domains")
 
  relaytable.each  do  |val|

       if val.index("#{domarray[1]}") != nil
               @flogger.info("#{@member}  : Sendmail Relay-Domain Table not changed : domain #{domarray[1]} exists in Relay Table")
               relay_table_flag = true
       end      

  end  #  end of loop

 
  ###############################################
  # Regenerate The Relaytable for a new domain
  ###############################################

  if relay_table_flag == false

        f1 = File.new("/etc/mail/relay-domains", "a+")
        f1.flock(File::LOCK_EX)
        f1.puts("#{domarray[1]}")
        f1.flock(File::LOCK_UN)

        @flogger.info("#{@member}: sendmail:relaytable entry added for  domain: #{domarray[1]}")

        f1.close()

   end   # end of if block
 



  #########################################
  #  Reload The Sendmail Config
  #########################################

   if mailer_table_flag == false  || relay_table_flag == false

      
        `cd /etc/init.d`
       `sh  /etc/init.d/sendmail force-reload  `

       @flogger.info("#{@member}: Sendmail : reload command issued")

   else

       @flogger.info("#{@member}: Sendmail Not Retarted : Domain existed in Mailer Table And Relay-Domains Table")


   end


   @flogger.info("#{@member}: Ruby Distributed Server Exiting : IMAP Account Created")
   @flogger.close()


  
  end   #  end of make_imap_account  method


  
  
  ########################################################################
  # delete_imap_account
  #######################################################################


  def delete_imap_account(mail_account, imap_account, debug)



    ########################
    #  Log Activity
    #######################

    @flogger =  Logger.new("/var/log/cryptmk.log", 20, 10000*1024)
    @flogger.datetime_format = "%Y.%m.%d : %H:%M:%S"

    if debug == 1
           @flogger.info("delete_imap_acount : #{mail_account}: Server Entry")
    end   

      

     @err = "" 


   
    ########################################################
    # Make A Raw Connection To The Cyrus Database
    #  (host, port, options, tty, database, user, password)
    ########################################################


   conn = PGconn.connect('localhost',5432, "", "", "***********", '**********','***********')

   if conn.nil? == true

     @flogger.error("delete_imap_account - Failed to open the postgres  database on localhost for root")
     @err = "Error : Failed To Open Authentication System"
     @flogger.close()
     return

   end

    if debug
           @flogger.info("delete_imap_account - #{mail_account}: Postgres database opened")
    end   



   #################################################
   # Delete  The Mail Account From The Mail Table
   #################################################
 
    begin
            res = conn.query("DELETE FROM crypticbox_users WHERE  user_uid = $1", [mail_account])

    rescue

    # restart the connection

       if conn.status() == CONNECTION_BAD

            conn = PGconn.connect('localhost',5432, "", "", "*************", '********','***********')

           if conn.nil? == true

               @flogger.error("delete_imap_account : FAILED TO REOPEN POSTGRES DATABASE AFTER DELETE HORDE USER  RECORD EXCEPTION")
               @err = "Error : Failed To Re-Open Connection"
               @flogger.close()
               return
           end

           if debug
                @flogger.warn("delete_imap_account : #{mail_account}: Postgres database Reopened After Exception closure")
           end

       end  # end of Connection_Bad block



    end  # end of exception block



   #################################################
   #  Test Account Deletion
   #################################################

   begin

       res = conn.query("SELECT * FROM crypticbox_users  WHERE user_uid=$1", [mail_account])
   rescue

            @flogger.error("delete_imap_account :  #{mail_account} In Horde Users Not Deleted")
            @flogger.close
	    @err = "Warning : Mail Account Deletion Error"
            return @err
   end


   ctr = 0
   res.each  do
       ctr += 1
   end

   if ctr > 0
            if ctr == 1
                @flogger.warn("delete_imap_account : #{mail_account} : account not deleted")
            elsif ctr > 0
                @flogger.error("delete_imap_account : #{mail_account}: MAJOR ERROR DUPLICATE HORDE ACCOUNTS")
            end            


            @flogger.close
            
            res.clear()
            conn.finish()
            return @err
   end



    if debug
           @flogger.info("delete_imap_account : #{mail_account}: Mail Account Deleted")
    end   


    res.clear()

  

  #####################################
  # close The PostGreSQL connection
  ###################################


   conn.flush()
   conn.finish()




  #################################################################
  # Delete The IMAP account 
  ##################################################################


#  imap = Net::IMAP::new('localhost')

  begin

      imap = Net::IMAP::new('localhost', 143)

  rescue

     @flogger.error("delete_mail_account : #{mail_account}: IMAP Constructor Failed")
     @flogger.close()
     err = "Error : IMAP Constructor Failed"
     return

  end


  if debug
           @flogger.info("delete_mail_account : #{mail_account}: IMAP Constructor Created")
  end




  ####################
  # IMAP Login
  ####################


  begin

      imap.login( '**************', '*************')

  rescue
     @flogger.error("delete_mail_account : #{mail_account}: IMAP login By User failed")
     @flogger.close()
     err = "Error : Cannot Login Into Mail Server" 
     return
  end


    if debug
           @flogger.info("delete_mail_account : #{mail_account}:  Admin Logged Into IMAP Account")
    end   


  ################################################
  #  Delete The  IMAP Account
  ################################################

  begin

     imap.delete("#{imap_account}")

  rescue
     imap.logout

     @flogger.error("delete_mail_account : #{imap_account}: FAILED - IMAP Account Deletion")
     @err = "Error : Cannot Delete IMAP Mail Account"           
 
     @flogger.close()
     return

  end



   if debug
           @flogger.info("delete_mail_account : #{imap_account}: IMAP Account Deleted")
   end   





  #####################
  # Logout of IMAP
  #####################


  imap.logout

    if debug
           @flogger.info("delete_mail_account : #{mail_account}: Logged Out Of IMAP Account")
    end   


    @flogger.close()

    return


   ########################################################################
   # Delete The Mailertable Entry
   # Careful: multiple members might use a mailer
   # table domain. Delete a domain only after 
   # ascertaining that there is no email account
   # using this domain
   #########################################################################


       # postpone - keep mailertable entries 
       # prune when table size > 10,000

  
  
  end  # end - delete_imap_account



  
  end  #  end of class
    

   
########################################################
#  Start The dRb Server
# 
########################################################



DRb.start_service("druby://x1.x2.x3.x4:11905",  MakeImapServer.new)
DRb.thread.join


