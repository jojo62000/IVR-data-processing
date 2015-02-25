#!/bin/sh

#input file for structuring


ivrheaderlocation=/home/jojo/data/ivrheader.txt
ivrstatelocation=/home/jojo/data/ivrstate.txt
ivrfunctionlocation=/home/jojo/data/ivrfunction.txt
ivrtimestamplocation=/home/jojo/data/ivrtimestamp.txt

FILENAME=/home/jojo/ivrold5sample.txt

echo "$buffer" > $ivrheaderlocation
echo "$buffer" > $ivrstatelocation
echo "$buffer" > $ivrfunctionlocation
echo "$buffer" > $ivrtimestamplocation

echo "Call_ID \$ DNIS \$ANI \$ Machine_ID \$ Channel_ID \$ Start_time \$ Total_time \$ Header_key " > $ivrheaderlocation
echo "Header_key \$ State_key \$ State_ID" > $ivrstatelocation
echo "Header_key \$ State_key \$ function_type \$ function_name \$ attribute \$ value_key \$ value" > $ivrfunctionlocation
echo "Header_key \$ State_key \$ State_ID \$ Timestamp" > $ivrtimestamplocation


#initialization of buffers, variables and flags
header_key=0
state_key=0
header_flag=false
fg=''
buffer=''
multiple_value_flag=0
state_flag=false

#main algorithm starts here

#pulling out calls from input file line by line (1 call = 1 line)

cat $FILENAME | while read LINE
 do
#  echo "inside first while loop line"
   onecall=$LINE 
   header_flag=false
   chbuffer=''
   chbuffer1=''	
  #echo "reset header flag"	
			
 len=`expr length "$onecall"`  # calculating length of  single line for traversal limits
 i=0 #initializing i as index to traverse through the call

header_key=$(( header_key+1 )) #incrementing header key for next call
state_key=0
header_flag= false
buffer=''

  while [ $i -le $len ]  #loop will continue the string is traversed completely
    do
	if [ $header_flag == false ]	
	 then
#	 echo "inside if loop for  header"
	 chbuffer1=''
         
#	 echo "chbuffer = $chbuffer "

	 while [ "$chbuffer" != ";;" ]
	  do
	 # echo "inside while loop for header and chbuffer = $chbuffer and i = $i"

	   if [ "$fg" = ";" ]
            then 
            delim="\$"
	    buffer=$buffer$delim

	   else 
   	    buffer=$buffer$fg

           fi #end of if fg = ';' check  

	   chbuffer1=$fg
	   fg=${onecall:$i:1}
	   i=$(( i+1 )) 
           chbuffer=$chbuffer1$fg 

	  done #end of while loop for chbuffer != ';;'
 	  header_flag=true
	# echo "buffer = $buffer"
         echo "$buffer$header_key" >> $ivrheaderlocation 
	 buffer=''
         i=$(( i-1 )) #decrementing the value of i as it will be incremented automatically at E.O.Loop

       else #if header traversing is completed
	#echo "ivr header_flag=false"	
	   #initializing related variables
	   #state_id=''
	   f_type=''
	   state_id=''
	   f_name=''
	   attribute=''
	   value=''
	   value_key=0	
	 	
           if [ "$fg" = ";" ] #bypassing the double ; after header
            then

	    while [ "$fg" = ";" ]
	    do
            fg=${onecall:$i:1}
	    i=$(( i+1 ))
	    done
    	     
           fi    
           
           while [ "$fg" != "|" ]
            do
    	    state_id=$state_id$fg
            fg=${onecall:$i:1}
	    i=$(( i+1 ))    	      		
  	    done 
	   state_key=$(( state_key +1 ))	
	   echo "state id = $state_id"	
	   echo "$header_key\$$state_key\$$state_id" >> $ivrstatelocation 

           if [ "$fg" = "|" ] #bypassing the '|' symbol
            then
            fg=${onecall:$i:1}
	    i=$(( i+1 ))    	     
           fi    

	   
	   f_type=''
	   while [ "$fg" != "|" ] && [ "$fg" != "("  ] 
            do
	    f_type=$f_type$fg		       	
            fg=${onecall:$i:1}
	    i=$(( i+1 ))    	      		
	    done
	   echo "ftype = $f_type"	

           if [ "$fg" = "(" ]  #for normal cases where we have f_names and values
            then
	     #now we will find either function name,value or atrribute-value combination 
	     
	     #first bypass the '(' symbol 
             fg=${onecall:$i:1}
	     i=$(( i+1 ))    	      		

	    
	     attribute=''
	     value=''
	     value_key=0
			
             while [ "$fg" != '(' ] && [ "$fg" != ')' ] && [ "$fg" != ',' ] && [ "$fg" != '=' ] && [ "$fg" != '[' ] && [ "$fg" != "]" ]
              do
	      f_name=$f_name$fg 	 	        			
              fg=${onecall:$i:1}
	      i=$(( i+1 ))    	      		
	      done	 
	      	
  	     if [ "$fg" = '(' ]  #rare case,ignore this & ')' twice   	
              then
	      brace_flag=false 
	      brace_counter=1 #used as a counter for bypassing multiple occurence of '(' and ')' pairs
	      echo "entered special handler for multiple '(' occurence"		
	      #this means, there is no function name - so add the result to value & update value key
	      value=$f_name
	      f_name='' 
	      while [ "$fg" != ")" ] && [ "$brace_counter" != "0" ]
	       do 
		 	 			
	       value=$value$fg
               fg=${onecall:$i:1}
	       i=$(( i+1 ))    	      	
	       if [ "$fg" = ")" ]
 		then
		brace_flag=true
	        brace_counter=$(( brace_counter-1 ))
		
               fi
	       if [ "$fg" = "(" ]
		then
		#increment brace_counter
		brace_counter=$(( brace_counter+1 ))
	       fi		 	 			
	       value=$value$fg
               fg=${onecall:$i:1}
	       i=$(( i+1 ))    	      		
	       done
	       value=$value$fg	
	       #echo "reached outside special handler for (( case and value = $value"	
	       echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation
	       value_key=$(( value_key+1 ))     	
               #this denotes the end of '(' case 
		

	     elif [ "$fg" = ")" ]
              then
	      #this means, there is no funciton name, but instead a single value
	      value=$f_name
	      f_name=''
	      echo "entered the ) case and printing ftype= $f_type and value = $value"
	      echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation
	      value_key=$(( value_key+1 ))     	
	      #this denote the end of ')' case
		
	     elif [ "$fg" = "," ]
	      then
	      #this means,there is no function name instead multiple values. Hence values and value_key needs to be handles
	      value=$f_name
	      f_name=''
	      echo "$header_key\$$state_key\$ $f_type\$ $f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation
	      value_key=$(( value_key+1 )) 
              value=''
              if [ "$fg" = "," ] #bypassing the ',' symbol
               then
               fg=${onecall:$i:1}
	       i=$(( i+1 ))    	     
              fi    

 
	      #traverse a loop to capture all values with value_keys
	      while [ "$fg" != ")" ]
               do
               value=$value$fg
               fg=${onecall:$i:1}
	       i=$(( i+1 ))    	     
              
                if [ "$fg" = "," ] #bypassing the ',' symbol
                then
	        echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation
	        value_key=$(( value_key+1 ))   
		value=''  	
                fg=${onecall:$i:1}
	        i=$(( i+1 ))    	     
                fi    	        	    		 
               done #done for while fg != ')'	    		      		 	
	       #this denotes the end of ',' case

              elif [ "$fg" = "=" ]
	       then
	       #this means that there is no f_name, instead a combination of attribute and value pairs
	       attribute=$f_name
	       f_name=''
 	       
               if [ "$fg" = "=" ] #bypassing the ',' symbol
                then
		echo "entered '=' conition"
                fg=${onecall:$i:1}
		        i=$(( i+1 ))    	     
               fi    
	       flag1=0
               while [ "$fg" != ")" ]
                do
		value=$value$fg
                fg=${onecall:$i:1}
	        i=$(( i+1 ))    	     

	        if [ "$fg" = "," ] 
	         then #this means that a pair of attribute and value is completed
	        echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation
	        attribute=''
		value=''    			
                fg=${onecall:$i:1}
	        i=$(( i+1 ))   
		flag1=1	 	     
		fi 

		if [ "$fg" = "=" ]
  		 then
		 #this means that attribute was copied to value
		 value=$attribute
		 value=''
                 fg=${onecall:$i:1}
	         i=$(( i+1 ))    	     
		fi
		done
		echo "comming out of while loop and flag1= $flag1"
		
		if [ "$flag1" = "0" ]
		then #for cases where there was only one pair without ',' symbol
		#echo "inside printing statement for special handler"
		echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation
		fi
	        
		#this denotes end of '=' case
     
                 #-----------------------------------------------------------------------------------
	
	       elif [ "$fg" = "[" ]
		then #this indicates the f_name exists and further we need to take care of attribute, value pairs
		#echo "entered  [ case"
                if [ "$fg" = "[" ] #bypassing the '[' symbol
                 then
	         echo "fname= $f_name" 
                 fg=${onecall:$i:1}
	         i=$(( i+1 ))    	     
                fi    
		
		while [ "$fg" != "<" ] && [ "$fg" != "=" ] && [ "$fg" != "]" ]
		 do
		 attribute=$attribute$fg
                 fg=${onecall:$i:1}
	         i=$(( i+1 ))    	     
		 done
                 echo "after while fg = $fg"
		 echo "attribute = $attribute : after while condition with <,=, and ] comparison"

                 #-----------------------------------------------------------------------------------		
		 if [ "$fg" = "<" ]
     		  then
   	           echo " entered attribute set condition"
		  # if fg = '<' then handle the code for Attribute-value set				 	
		  #embedding the code from ivrsample.sh

 		   attribute='' 
	           #echo "i cme here"
		   #it means that attribute set name was stored, hence we flush the variable	
		   #here we have pairs of attribute and value terminated by '>' symbol 					
		   fg=${onecall:$i:1}
		   i=$(( i+1 ))
		    while [ "$fg" != ">" ] && [ $i -le $len ]
		     do
			#echo "beginin  fg= $fg"
			while [ "$fg" != "=" ] && [ $i -le $len ]
			 do
		          attribute=$attribute$fg
			  fg=${onecall:$i:1} 		
			  i=$(( i+1 ))
		         done		
			 echo "Attribute = $attribute and fg = $fg"
			 
			 if [ "$fg" = "=" ]
			 then
			 fg=${onecall:$i:1}
			 i=$(( i+1 ))	
			 value=''
			 value_key=0	
			 while [ "$fg" != "," ] && [ $i -le $len ]
			 do

 		           if [ "$fg" = "{" ]
			   then
			  
			     #bypass the '{' symbol
		             if [ "$fg" = "{" ]
			     then
			     fg=${onecall:$i:1}
			     i=$(( i+1 ))	
		             fi
			
			   while [ "$fg" != "}" ]
		           do		
			   if [ "$fg" = ";" ]	
			   then
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))

			   #multiple values exist, we need to handle value_key
		           echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation
			   #now reset value variable to null
	 		   value=''
			   value_key=$(( value_key+1 )) 	  					  
 			   fi			      
					
			   value=$value$fg
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))
	                   done 	
		  	   if [ "$fg" = "}" ]
			   then
		            fg=${onecall:$i:1}
			    i=$(( i+1 ))	
			
			   echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value " >> $ivrfunctionlocation
			   value=''
			   fi	
			
		       else
		           value=$value$fg
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))
	                

                     fi #end of if condition for fg = { 		
			    
		      
			 done	
			 #at this point  of time,  we have a pair of attribute and value 
	                 echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation

			 echo "value = $value"
			 fi #end of if fg = '='

			attribute=''
			if [ "$fg" = "," ]
			 then
			 #echo "inside if fg = ','"
			  fg=${onecall:$i:1}	
			  i=$(( i+1 ))
	                  #echo "fg =$fg before entereing if fg = >,"
                           #check if next char is '>'
	                    
                            if [ "$fg" = ">" ]	
   			     then
			     #echo "inside if fg = >"
			      fg=${onecall:$i:1}	
			      i=$(( i+1 ))
			       #echo " fg=$fg,"	
				if [ "$fg" = "," ]			     
      				 then		
			          #echo "inside if fg = ',' part 2"	
			          while [ "$fg" != "<" ] && [ $i -le $len ]
			           do	
			 	    fg=${onecall:$i:1}	
			            i=$(( i+1 ))
	      		           done
	
				     if [ "$fg" = "<" ]
				     then
		  		     #echo "inside if fg = '<' for 2nd set FG = $FG"
			             fg=${onecall:$i:1}	
			             i=$(( i+1 ))
				     fi #end of fg = <

				elif [ "$fg" = "]" ]
				then
			         #echo "FOUND ] , BREAK FG= $FG"
				break;

				else 
				echo "exiting attribute sets"
						 	
				fi #end of fg = ,			
			    fi #end of if fg = >				       			 
			fi #end of fg = ,
			#echo "end of while - fg=$fg,"
			value_key=0
		     done
		
                   


 		 elif [ "$fg" = "]" ]
		 then
	         #echo "or i came here"
		 #rare case scenario, where the function has only 1 single value
	         value=$attribute
		 attribute=''
		 echo " entered value = $value"
	  	 echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation		       				
		 
                 #-----------------------------------------------------------------------------------
		 else
		 #if fg = '=' then there are attribute-value pairs
		 
	         #start of code embeding from above case
	         #echo "entered  = loop and attribute = $attribute and fg = $fg fname = $f_name and ftype = $f_type and header=$header_key"
                  if [ "$fg" = "=" ] #bypassing the '=' symbol
                  then
	          echo " attribute = $attribute"
		   fg=${onecall:$i:1}
	           i=$(( i+1 )) 
	          #echo "fg = $fg"
                  fi    

	     	  value=''
		  var1=''	
		  value_key=0
                  while [ "$fg" != "]" ]
                  do
		#echo "inside while fg = ']'"
	     if [ "$fg" = "{" ]
			   then
			  
			     #bypass the '{' symbol
		             if [ "$fg" = "{" ]
			     then
			     fg=${onecall:$i:1}
			     i=$(( i+1 ))	
		             fi
			
			   while [ "$fg" != "}" ]
		           do		
			   if [ "$fg" = ";" ]	
			   then
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))

			   #multiple values exist, we need to handle value_key
		           echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value " >> $ivrfunctionlocation
			   #now reset value variable to null
	 		   value=''
			   value_key=$(( value_key+1 )) 	  					  
 			   fi			      
					
			   value=$value$fg
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))
	                   done 	
		  	   if [ "$fg" = "}" ]
			   then
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))
	        	   echo "for attribute value pair: attribute= $attribute and value = $value"	
			   echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value " >> $ivrfunctionlocation
			   value=''
	                   multiple_value_flag=1
			   fi	               
                           

                     fi #end of if condition for fg = { 


#-------------------------------------------------------

		       
		           
		           if [ "$fg" = "," ]
			   then
			   #found 1 attribute value pair
			   value=$var1

			   echo "attribute=$attribute value =$var1 and fg=$fg fname=$f_name ftype = $f_type headerkey = $header_key"
			   echo "entered single value combination step"

			   # only printing values to a file if '{' occurrence multiple values were not found			   
			   if [ "$multiple_value_flag" = "0" ]
		           then
			   echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value " >> $ivrfunctionlocation	
		           else
			   multiple_value_flag=0
			   fi
			   # only printing values to a file if '{' occurrence multiple values were not found	
			   value=''
			   var1=''
			   attribute=''	
			   #echo "before bypass fg=$fg"
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))
		      	   #echo "after bypass fg=$fg"	
			   		
			   
		           elif [ "$fg" = "=" ]
			   then
			   attribute=$var1
			   var1=''	
			   echo "attribute = $attribute and ftype=$f_type fname=$f_name"
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))
			   	
	
			   else 
			   var1=$var1$fg
			   fg=${onecall:$i:1}	
			   i=$(( i+1 ))
                            fi 
	           	value_key=0
		#echo "last line before while fg = ']'"
#---------------------------------------------------------
	   done
	   #echo "outside while fg = ]"
#------------------end of sub code----------------------------------------		
		
		#this denotes end of '=' case
	
		 
		#end of code embedding
			 	 
			             
 	     fi #end of IF condition for comapring '(' or ')' or ','  or '=' or '[' or ']'
	    else # if fg = | -special handler for XH and T	
	    #echo "entered else handler for XH"	
	      echo "special handler"
	       echo "$header_key\$$state_key\$$f_type\$$f_name\$$attribute\$$value_key\$$value" >> $ivrfunctionlocation

	   #handle time stamp
	   if [ "$fg" = "|" ] || [ "$fg" = ")" ] || [ "$fg" = "]" ]
	    then
	   echo "entererd timestamp and fg = $fg"	
	    if [ "$fg" = ")" ] || [ "$fg" = "]" ]
             then
 	      while [ "$fg" != "|" ]
	       do
                fg=${onecall:$i:1}
	        i=$(( i+1 ))
		
	       done 		
	   
            fi #check for '|' or ')' occurence

	    #bypass '|'  	
    	    fg=${onecall:$i:1}
	    i=$(( i+1 ))
            
            timestamp=''
	    while [ "$fg" != ";" ]
	     do
	      timestamp=$timestamp$fg
    	      fg=${onecall:$i:1}
	      i=$(( i+1 ))
	
	     done
			
	    echo "$headerkey\$$state_key\$$state_id\$$timestamp" >> $ivrtimestamploation 
	   state_flag=true
					
	    echo " timestamp = $timestamp and fg = $fg and printing to ivrtimestamp.txt :timestamp1"

    	   tbuffer1=$fg
	   tbuffer2=${onecall:$i:1}
	   tbuffer=$tbuffer1$tbuffer2
	   
            if [ "$tbuffer" = ";;" ]
 	     then
	      #end of call, now bypass all characters till you find \n
             i=$len		
   	    fi #end of tbuffer  = ';;'
	 		
	   fi	#end if timestamp handler	

           #end of else loop for XH handler     
	   fi
 	   
	   #handle time stamp

	   if [ "$fg" = "|" ] || [ "$fg" = ")" ] || [ "$fg" = "]" ]
	    then
	    echo "entered main timestamp handler "	
	    if [ "$fg" = ")" ] || [ "$fg" = "]" ]
             then
 	      while [ "$fg" != "|" ]
	       do
                fg=${onecall:$i:1}
	        i=$(( i+1 ))
		
	       done 		
	   
            fi #check for '|' or ')' occurence

	    #bypass '|'  	
    	    fg=${onecall:$i:1}
	    i=$(( i+1 ))
            
            timestamp=''
	    while [ "$fg" != ";" ]
	     do
	      timestamp=$timestamp$fg
    	      fg=${onecall:$i:1}
	      i=$(( i+1 ))
	
	     done
				
   	    echo "$header_key\$$state_key\$$state_id\$$timestamp" >> $ivrtimestamplocation
	    state_flag=true
	    echo " timestamp = $timestamp and fg = $fg and len= $len and  i =$i :timestamp2"
 	    
	    
    	   tbuffer1=$fg
	   tbuffer2=${onecall:$i:1}
	   tbuffer=$tbuffer1$tbuffer2
	   
            if [ "$tbuffer" = ";;" ]
 	     then
	      #end of call, now bypass all characters till you find \n
	     i=$len	
            fi 		
		
	    echo " timestamp = $timestamp and fg = $fg"		
	   fi	#end if timestamp handler	
			 		
      echo "second last if loop fg = $fg"
	 
       fi #end of check for header flag = false  
echo "last if loop fg =$fg"

  if [ "$fg" = "|" ] 
	 then
	   #echo "entered if condition"
	   #handle time stamp
	   if [ "$fg" = "|" ] || [ "$fg" = ")" ] || [ "$fg" = "]" ]
	    then
	    if [ "$fg" = ")" ] || [ "$fg" = "]" ]
             then
 	      while [ "$fg" != "|" ]
	       do
                fg=${onecall:$i:1}
	        i=$(( i+1 ))
		
	       done 		
	   
            fi #check for '|' or ')' occurence

	    #bypass '|'  	
    	    fg=${onecall:$i:1}
	    i=$(( i+1 ))
            
            timestamp=''
	    while [ "$fg" != ";" ]
	     do
	      timestamp=$timestamp$fg
    	      fg=${onecall:$i:1}
	      i=$(( i+1 ))
	
	     done
	    echo "$header_key \$ $state_key \$ $f_type \$ $f_name \$ $attribute \$ $value_key \$ $value" >> $ivrfunctionlocation
	      echo "$header_key\$$state_key\$$state_id\$$timestamp" >> $ivrtimestamplocation		
	      
	
	    echo " timestamp = $timestamp and fg = $fg and len= $len and  i =$i :timestamp3"

    	   tbuffer1=$fg
	   tbuffer2=${onecall:$i:1}
	   tbuffer=$tbuffer1$tbuffer2
	   
            if [ "$tbuffer" = ";;" ]
 	     then
		echo "inside new ;; handler"
	      #end of call, now bypass all characters till you find \n
              i=$len
		 		
   	    fi 
		
	   fi	#end if timestamp handler	
	 fi

         if [ "$fg" = ";" ]
	 then
	 #echo "entered last if "
	    while [ "$fg" = ";" ]
	      do 	
	      fg=${onecall:$i:1}
	      i=$(( i+1 ))
	      done 
		
        	  	
			 		 	 	
         fi #special case handler
      
 if [ $i -ge $len ]
 then
 echo "enter break condition inside"
 header_flag=false
 break 
 fi

         
fi		
#     i=$(( i+1 )) 	
    done #end of do loop for char by char traversal
echo "out of 2nd last while loop i = $i and len = $len"
 
 if [ $i -ge $len ]
 then
 echo "enter break condition outside and headerkey =$header_key																							 "
 header_flag=false
 
 #break 
 fi
 
 done #end of do loop for call by call traversal	


