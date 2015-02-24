//DECLARATION OF HEADER FILES
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

// DECLARATION OF FILE POINTERS FOR OUTPUT FILES 
FILE *header_file=NULL;
FILE *function_file=NULL;
FILE *state_file=NULL;

//START OF THE MAIN PROGRAM
int main(int argc, char *argv[])
 {
  char fg = ' ';
  int m=0,k=0,j=0;		
  FILE *fp = NULL;	  	
  long int header_key=0,state_key=-1,value_key=0;
  char header[3000],state_id[20],function_type[20],function_name[50],attribute[50],value[100],timestamp[200];
  int header_flag=0,state_flag=0,function_type_flag=0,function_name_flag=0;
  char chbuffer1[5], chbuffer2[2];	
  char buffer[100];	
   
  // OPENING THE CURRENT FILE WITH IVR LOG FILE
  fp = fopen(argv[1],"r") ;
 
    if(fp == NULL)
	{
	 printf("Error opening file");
	 exit(0);
	}	
//IF THE LOG FILE DOES NOT EXIST , THIS PROGRAM WOULD TERMINATE

    header_file = fopen(argv[2], "w");
    state_file = fopen(argv[3], "w");    
    function_file = fopen(argv[4], "w"); 

//CORE LOGIC FOR THE LOG FILE PARSING, END OF THE MAIN WHILE LOOP

  while(1)
   {
     	printf("\ninside while1 and fg = %c",fg);	
	if(fg == ';' || fg == ' ')
	  {
	  	
	    while(fg == ';' || fg == ' ')
	    {		
	      fg=fgetc(fp);		
	      printf("\n inside initial while fg = ';' and fg extracted as %c",fg); 		
            }
	  } 		
         printf("\n before eof comparison fg = %c",fg);
	 
        if(fg == '\n')
          {
	   printf("\n new call");
 	   //new call, initialize the variables for a new call
	   header_flag=0;
	   state_flag=0;
	   function_name_flag=0;
	   function_type_flag=0;
 	   	   	
	   if(header_key%1000 == 0)
		{
		  fclose(header_file);
		  fclose(function_file);
		  fclose(state_file);

		      header_file = fopen("/home/jojo/data/ivrheader.txt", "a");
		      state_file = fopen("/home/jojo/data/ivrstate.txt", "a");    
		      function_file = fopen("/home/jojo/data/ivrfunction.txt", "a"); 
		     printf("\nReopened the file connection");	
			
		  
		}
	   printf("\n call_id = %ld",header_key);
	   header_key++;
	   state_key=-1;	
	   value_key=0;
           strcpy(buffer,"");
	   strcpy(attribute,"");
	   strcpy(value,"");
	   strcpy(state_id,"");
	   strcpy(function_type,""); 
	   fg = fgetc(fp);	
          }
         
         if(fg == EOF)
            {
             // new call
	     printf("\n end of file");	
     
               break; 
            } 
         else
	  {
	 
	    if(header_flag == 0)
	     {
		j=0;
               while(strcmp(chbuffer1,";;")!=0)
     		{
                 
		 if(fg == ';') 
		   header[j++]='$';
		 else
        	   header[j++]=fg;		       	
		
		 chbuffer1[0]=fg;
		 fg = fgetc(fp);
		 chbuffer1[1]=fg;
		 chbuffer1[2]='\0'; 		 
		}
	      // comes out of while loop after finding a ';;' pattern	     
		
              //strcpy(header,header_key);
                header[j++]='\0';
		fprintf(header_file,"%s%ld\n",header,header_key);			
                header_flag=1;
		printf("\n finished parsing header fo call id = %ld",header_key);
	     } // end of header_flag = 0 : if part
	    else
	     {
		//ONE CALL WILL HAVE ONLY 1 HEADER, ONCE THE HEADER IS PARSED THE STATE TRANSITION NEEDS TO BE PARSED
		if(state_flag == 0)
                {
  		  printf("entered the state_flag = 0 condition\n");
	          int i=0;
		  while(fg != '|')
                  {
	           state_id[i++]=fg;
		   fg = fgetc(fp);
	          } 
	           state_id[i++]='\0';
                   printf("state_id = %s\n",state_id);
		   state_flag=1; 	
                } //if state_flag is 0
		
	       fg = fgetc(fp); // bypass the current '|' symbol
		
	       //AFTER THE STATE ID IS STORED, WE NEED TO MOVE AHEAD TO STORE THE FUNCTION TYPE		
	       if(function_type_flag == 0)
 		{
		  int i=0;
		  while(fg != '(' && fg != '|')
                  {
	           function_type[i++]=fg;
		   fg = fgetc(fp);
	          } 
	           function_type[i++]='\0';
                   printf("function_type = %s\n",function_type);
		   function_type_flag=1;
		} // function_type_flag is 0
                 

		//AFTER THE FUNCTION TYPE IS STORED, THE NEXT CHARACTER WOULD BE EITHER '(' OR '|'
		// '|'INDICATES THAT THERE IS NO FUNCTION NAME OR ATTRIBUTE-VALUE PAIRS

		//IF '|' OCCURS, THIS MEANS THAT THERE IS A SPECIAL FUNCTION - XH/T/S WHICH NEEDS TO BR HANDLED SEPARATELY
                if(fg == '|')
		  {
                   printf("\n found special case handler for | XH");// directly to timestamp handler
		   fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);	

		  }
                else // runs for all cases where XH and other special handlers are not necessary
		{
		 fg = fgetc(fp); //bypassing the current '(' symbol

                 //copy till you find '(',')', ',', '=', '['
		 m=0;
		 //NOW, WE HAVE THE FUNCTION TYPE STORED

		 /*
		 NEXT OCCURENCE OF 
                 '('	 - INDICATED A SPECIAL CASE, WHERE THERE IS ONLY VALUE WITH NO FUNCTION NAME OR ATTRIBUTES, 
			   THIS NEEDS TO BE ADDED TO THE VALUE ITSELF
		 ')'	 - INDICATED AS 1 SINGLE VALUE
		 ',' 	 - INDICATED AS OCCURENCE OF MULTIPLE VALUES
		 '='	 - INDICATED AS OCCURENCE OF ATTRIBUTE - VALUE PAIRS
		 '[' 	 - INDICATES THAT FUNCTION NAME EXISTS	
		 */	
		
		 //PARSING UNTIL ANY OF THE ABOVE MENTIONED ELEMENTS ARE FOUND	
		 while(fg != '(' && fg != ')' && fg != ',' && fg != '=' && fg != '[' )
                  { 
		   buffer[m++]=fg;
    		   fg = fgetc(fp); 
     		  }
		  
		  //HANDLE THE SPECIAL CASE AND  THE STORE END RESULT AS A VALUE
		  if(fg == '(')
		   {
		        int a=1;
		        
			printf("\n inside top level '(' case");
			while(a!=0)
			 {
			  if(fg == '(')
			   a++;

			  if(fg == ')')
	 		   a--;

			  if(a >= 1)
			  buffer[m++]=fg;

			  fg=fgetc(fp);		
			 }
		   buffer[m++]='\0';
		   strcpy(value,buffer);
		   fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);	

		   }		
		  
		  //HANDLER FOR OCCURENCE OF A SINGLE VALUE	
                  else
                  if(fg == ')')
		   {
		    printf("\ninside top level ')' case");
 		    // this means that there is a single value and no function name
		    buffer[m++]='\0';
	            strcpy(value,buffer);
		    printf("value = %s",value);	
		    fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);

		   } 

		  //HANDLER FOR OCCURENCE OF MULTIPLE VALUES 
	     	  else
		  if(fg == ',')
		   {
		    printf("\ninside top level ',' case");
		    //there are multiple values in the function type without the function name
		    while(fg != ')')
		     {
		      if(fg == ',')
  		       {
 		        buffer[m++]='\0';
	                strcpy(value,buffer);
		        printf("\nvalue = %s",value);
			fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);
		        strcpy(buffer,"");	 
		        m=0;	
		       }	 
		      else
		       {
		        buffer[m++]=fg;
		       }		 	 	
    		        fg = fgetc(fp); 				
		     }// end of while loop for top level ',' handler
	
		   }// end of top level ',' handler
		  
		  //HANDLER FOR OCCURENCE OF ATTRIBUTE - VALUE PAIRS 
		  else 
		  if(fg == '=')
		   {
		    printf("\ninside top level '=' case");
		    // could be a single or multiple attribute, value pairs
	            while(fg!=')')
		     {
		       if(fg == '=')// then found attribute, value needs to copied	
			{
			 buffer[m++]='\0';
		         strcpy(attribute,buffer);
			 strcpy(buffer,"");
			 m=0;
		         fg = fgetc(fp); // BYPASSING  '=' SYMBOL : NEEDS TO BE AVOIDED FROM GETTING STORED AS A PART OF THE VARIABLE 
			}	
		       
		       if(fg == ',') // found a pair of A&V,	
			{
			 buffer[m++]='\0';
		         strcpy(value,buffer);
			 printf("\n Attribute = %s, value = %s",attribute,value);
			 fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);
			 strcpy(buffer,"");
			 m=0;
			 fg = fgetc(fp);   // BYPASSING  ',' SYMBOL :NEEDS TO BE AVOIDED FROM GETTING STORED AS A PART OF THE VARIABLE
			} 		
		         buffer[m++]=fg;
			 fg = fgetc(fp);
			
			if(fg == ')')
			 {
			 buffer[m++]='\0';
		         strcpy(value,buffer);
			 printf("\n Attribute = %s, value = %s",attribute,value);
			 fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);
			 strcpy(buffer,"");
			 m=0;  			  	
			 }	
		      } //end of while fg != ')' in top level '=' case	

		   }		 		     

		  //HANDLER FOR FUNCTION - NAME AND FURTHER PROCESS	
		  else
		  if(fg == '[')
		   {
		    fg=fgetc(fp);	
		    printf("\ninside top level '[' case");
		    // function name exists	
		    buffer[m++]='\0';
		    strcpy(function_name,buffer);
		    strcpy(buffer,"");
		    printf("\nfunction name = %s\n",function_name) ;
		    m=0;
		    while(fg != ']' && fg != '=' && fg != '<')
		     {
		       buffer[m++]=fg;
		       fg=fgetc(fp);		
		       //printf("\n inside while fg = %c",fg); 
		     } 
		       printf("\n after while fg = %c",fg);
		       //here fg takes either ']', '=' or '<' :all cases needs to be handled separately
                     
		     if(fg == ']')
		      {
			printf("\n inside second level ']' case after '['");
		        printf("\ninside [ -> ]");	
			buffer[m++]='\0';
			strcpy(value,buffer);
			strcpy(buffer,"");
			fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);
			printf("\n value = %s",value);		
		      }
		     else
		     if(fg == '=')
		      {
			printf("\n inside second level '=' case after '['");
	 	        int eflag =0;
			while(fg != ']')
			  {
		 	    if(fg == ',' ) // 1 pair of attribute & value is found
			      {
				fg=fgetc(fp);	
				buffer[m++]='\0';
				m=0;
				strcpy(value,buffer);			     
				printf("\n A=%s and V=%s",attribute,value);
					       
				fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);
				value_key=0;
			 	strcpy(buffer,"");
			        strcpy(attribute,"");
				eflag=0;
			      }
		            else
		 	    if(fg == '=')// found attribute, traverse for value
 			      {
				fg=fgetc(fp);	
				buffer[m++]='\0';
				m=0;
				strcpy(attribute,buffer);
				strcpy(buffer,"");
				printf("\n in = attribute = %s",attribute); 
			      } 
			    else
			    if(fg == '{')
                              {
                               fg=fgetc(fp); // bypass '{'
                               value_key=0; 
				m=0;
			       while(fg != '}')
				{
				  if(fg == ';')
				   {
				     buffer[m++]='\0';
				     strcpy(value,buffer);
				     m=0;		
				     printf("\n value = %s and valuekey = %ld",value,value_key);
				     fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);	
				     eflag=1;
       				     value_key++;
				     fg=fgetc(fp);		
       				   }
                                  else
				   {
				     buffer[m++]=fg;
				     fg=fgetc(fp); 	
				   } 
				}
                                buffer[m++]='\0';
				strcpy(value,buffer);    		
				printf("\n value = %s and valuekey = %ld",value,value_key);				
			      }
	
			     else 	
			     if(fg == '}')
                               fg=fgetc(fp);

                             else
			      {	
			        buffer[m++]=fg;
				fg= fgetc(fp);	
			      }   	     		

			    }//end of while loop for fg != ']' for second level '=' case after '['	

		      }
		     else
		     if(fg == '<')
		      {
		        printf("\n inside second level '<' case after '['");	
			printf("\ninside [ -> <");
			strcpy(buffer,"");
			fg= fgetc(fp);
			m=0;

			while(fg != ']')
			 {
			   if(fg == '=') // attribute found
			    {
			      buffer[m++] = '\0';
			      m=0;
			      strcpy(attribute,buffer);	
			      strcpy(buffer,"");
			      // printf("\n inside = handler, attribute = %s",attribute);
			      fg = fgetc(fp);
                              if(fg != ',')						   				
			      	{
				  buffer[m++] = fg;
				  fg=fgetc(fp);
				}
			    }
			   else	
		           if(fg == ',') // found value
			    {
			      buffer[m++]='\0';
			      m=0;	
			      strcpy(value,buffer);
			      printf("\n Attribute = %s and value = %s",attribute, value);	
			      fprintf(function_file,"%ld$%ld$%s$%s$%s$%ld$%s\n",header_key,state_key,function_type,function_name,attribute,value_key,value);	
			      fg = fgetc(fp);
			      //buffer[m++] = fg;
			    }
			  else	
			  if(fg == '>')
			   {
 			    printf("\n inside  > handler"); 
			    fg = fgetc(fp);

 			    if(fg == ',') // multiple  attribute sets exist
			      {
				fg = fgetc(fp);	
			      }	
				printf("\n inside > handler and fg = %c",fg);		
									
			    }
	   		   else		
			   if( fg == '<')
			    {
			     m=0;
			     strcpy(buffer,"");			
			     fg = fgetc(fp);	
			     //buffer[m++] = fg;
		   	    }
			   else
			    {
		             if(fg != ',' && fg != '=')	
			     {			
                              buffer[m++] = fg;
                             }
			      fg = fgetc(fp);	

			    } 	
	
			 } // end of while fg != ']' for second level '<' case after '[' 

		      }
		     else
		      {
                        printf("unhandled second level case after '['");
		      }			 							
			  

				
		   }                            
		  else
		   {
		     printf("\n unhandled top level case");
		   }
   
             } // else part for XH and XC handler
    
	     }// end of if(header = 0): else part		

	      // handle timestamp 
	     if(fg == ')' || fg == ']' || fg == '|')
               {
		 printf("\n inside timestamp handler");	

		 if(fg == ')')
		    while(fg != '|') //bypass all characters till '|'
		      fg=fgetc(fp);

		 if(fg == ']' )
		    while(fg != '|')
		      fg = fgetc(fp);

		 if(fg == '|')
                   {
		      fg=fgetc(fp); // bypass '|' symbol
		      m=0;
		      while(fg != ';')
		        {
			  buffer[m++]= fg;
			  fg = fgetc(fp);		
			}

		      buffer[m++] = '\0';
		      strcpy(timestamp,buffer);
		      printf("\n timestamp = %s",timestamp);	
		      state_flag=0;
			  		
		     }
                 fprintf(state_file,"%ld$%ld$%s$%s\n",header_key,state_key,state_id,timestamp);	 
		 }//end of timestamp handler						         	
		printf("\n outside timestamp handler");
                strcpy(chbuffer2,"");	  		       	
		 chbuffer1[0]=fg;
		 fg = fgetc(fp);
		 chbuffer1[1]=fg;
		 chbuffer1[2]='\0';
 	         if(strcmp(chbuffer1,";;")==0)
                   {
                    //end of call
		    //header_key++;
                    fg=fgetc(fp);  
                   } 	
                if(fg == '\n' || fg == EOF)
                    printf("\n found new line or EOF");

             printf("\n after final traversal fg =%c",fg);		

		//reseting memory
		//header_flag=0;
	    	state_flag=0;
	    	function_type_flag=0;
	    	function_name_flag=0;
		state_key++;	
	   	 //header_key++;
	    	value_key=0;
	    	strcpy(function_type,"");
	    	strcpy(header,"");	
	    	strcpy(function_name,"");
	    	strcpy(attribute,"");
	    	strcpy(value,"");
	    	strcpy(chbuffer1,"");
	    	strcpy(chbuffer2,"");


	  }// end of if(fd == EOF) and else part 		 
	printf("\n last part of while1 anf fg =%c",fg);
printf("\n line of while 1");
	
   }//end of while(1) loop	 		

  //closing all open connections
  fclose(header_file);
  fclose(function_file);
  fclose(state_file);
  printf("\n done with main file");
  exit(0);

 }//end of main 		
