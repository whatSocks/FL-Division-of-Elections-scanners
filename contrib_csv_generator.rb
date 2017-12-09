require 'rest_client'
require 'mechanize'

contributions_list_url = 'http://election.dos.state.fl.us/campaign-finance/contrib.asp'
contrib_list_file = File.open("output/contrib_list.csv", "w")
contrib_list_file.write("Candidate/Committee  Date  Amount  Typ Contributor  Address City State Zip  Occupation  Desc\n")

agent = Mechanize.new

begin
  page = agent.get(contributions_list_url)
rescue Exception => e
  p "ERROR: #{e}"
  p "RETRYING IN 30 SECONDS"
  sleep 30
retry
end

# The value 'All' is located at index 0, so we exclude that one from the scan
# Trying to ask the website for 'All' causes an error, so you have to go incrementally
election_option_arr = page.search('select[name="election"] option').map { | option | option['value']
}[1.. - 1] 
election_name_arr = page.search('select[name="election"] option').map { | option | option.text
}[1.. - 1]

election_option_arr.zip(election_name_arr){|election_value, election_text|
      ['CanLName', 'ComName'].each { | record_type | [ * ('a'..'z'), * ('0'..'9')].each { | letter_number |
          begin
            page = agent.get(contributions_list_url)
          rescue Exception => e
            sleep 30
          retry
          end

          # The form, in Mechanize object format
          doe_form = page.forms[0]

          # This goes in the candidate "Last name" field.
          # By default, "With candidate last name starts with"
          # is checked off, so we search all candidates whose last name begins with this letter
          doe_form[record_type] = letter_number

          # Search all elections in the DOE campaign finance database
          doe_form['election'] = election_value 

          # Sort by earliest to latest contributions.
          doe_form['csort1'] = 'DAT' 

          # NO LIMIT on how many records the query returns
          doe_form['rowlimit'] = ''

          # Check off the button for downloading DOE results in tab - delimited file
          doe_form.radiobuttons[15].check
          
          if (record_type === 'CanLName')
            # Makes sure we click the "Search for a list of contributions"
            # button, so we see each contribution to each candidate
            doe_form.radiobuttons[5].check 
          else
            # Same as above, but for committees
            doe_form.radiobuttons[10].check
          end
          begin
            result = doe_form.submit.body
            contrib_list_file.write(result.sub(/.*\n/,''))
          rescue Exception => e
            sleep 30
          retry
          end
        }
      }
  end
}

contrib_list_file.close()