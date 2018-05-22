require 'rest_client'
require 'mechanize'
require 'date'
require 'securerandom'

contributionsListURL = 'http://election.dos.state.fl.us/campaign-finance/contrib.asp'

investigateCSV = File.open("output/investigate.csv", "w")

# get candidate data - some will be incomplete, so get only the candidate, amount, date, contributor
candidatesCSV = File.open("output/candidates.csv", "w")
# candidatesCSV.write("Candidate\tParty\tOffice\tDay\tMonth\tYear\tAmount\tType\tContributor\tAddress\tCity\tState\tZip\tNotes\n")
candidatesRegex = /(?<recipient>.+)\s\((?<recipientParty>[A-Z]{3})\)\((?<office>[A-Z]{3})\)\t(?<day>[0-9]{2})\/(?<month>[0-9]{2})\/(?<year>[0-9]{4})\t(?<amount>.+)\t(?<paymentType>[A-Z]+)\t(?<name>.+)\t(?<addr>.+)\t(?<city>.+),\s(?<state>[A-Z]{2})\s(?<zip>[0-9]{5})(\t)?(?<occu_desc>.+)/

limitedCandidatesCSV = File.open("output/candidatesLimited.csv", "w")
# limitedCandidatesCSV.write("Candidate\tParty\tOffice\tDay\tMonth\tYear\tAmount\tType\tContributor\n")
limitedCandidatesRegex = /(?<recipient>.+)\s\((?<recipientParty>[A-Z]{3})\)\((?<office>[A-Z]{3})\)\t(?<day>[0-9]{2})\/(?<month>[0-9]{2})\/(?<year>[0-9]{4})\t(?<amount>.+\.[0-9]{2})\t(?<type>[A-Z]+)\t?(?<contributor>)\t/

# get committee data - some will be incomplete, so get only the committee, amount, date, contributor
committeesCSV = File.open("output/comittees.csv", "w")
# committeesCSV.write("Committee\tCommitteeType\tDay\tMonth\tYear\tAmount\tType\tContributor\tAddress\tCity\tState\tZip\tOccupation\tDesc\n")
committeesRegex = /(?<recipient>.+)\s\((?<recipientType>[A-Z]{3})\)\t(?<day>[0-9]{2})\/(?<month>[0-9]{2})\/(?<year>[0-9]{4})\t(?<amount>.+)\t(?<paymentType>[A-Z]+)\t(?<name>.+)\t(?<addr>.+)\t(?<city>.+),\s(?<state>[A-Z]{2})\s(?<zip>[0-9]{5})\t(?<occu_inkind>.*)/

limitedCommitteesCSV = File.open("output/committeesLimited.csv", "w")
# limitedCommitteesCSV.write("Candidate\tParty\tOffice\tDay\tMonth\tYear\tAmount\tType\tContributor\n")
limitedCommitteesRegex = /(?<recipient>.+)\s\((?<recipientType>[A-Z]{3})\)\t(?<day>[0-9]{2})\/(?<month>[0-9]{2})\/(?<year>[0-9]{4})\t(?<amount>.+\.[0-9]{2})\t(?<type>[A-Z]+)\t(?<contributor>[^\t]+)\t/

agent = Mechanize.new

begin
  page = agent.get(contributionsListURL)
rescue Exception => e
  p "ERROR: #{e}"
  p "RETRYING IN 30 SECONDS"
  sleep 30
retry
end

def getContributions(resultType, range, step, page, goodData, goodRegex, limitedData, limitedRegex, investigate)
  puts "step size: " + step.to_s
  puts "range: " + range.to_s
  range.step(step) {|date_step|
    doe_form = page.forms[0]
    # Search all elections in the DOE campaign finance database
    doe_form['election'] = 'All' 

    # Sort by earliest to latest contributions.
    doe_form['csort1'] = 'DAT' 

    # NO LIMIT on how many records the query returns
    doe_form['rowlimit'] = ''

    # Check off the button for downloading DOE results in tab - delimited file
    doe_form.radiobuttons[15].check

    # Looking for contributions towards candidates or committes?
    # candidate search is radio button 5
    # committee search is radio button 10
    doe_form.radiobuttons[resultType].check

    doe_form['cdatefrom'] = date_step.strftime("%m/%d/%Y")
    doe_form['cdateto'] = (date_step + step - 1).strftime("%m/%d/%Y")
    puts date_step.to_s + " - " + (date_step + step - 1).to_s

    # remove quote characters from the data
    begin
      result = doe_form.submit.body.sub(/.*\n/,'')
    rescue Exception => e
      p "ERROR: #{e}"
      p "RETRYING IN 30 SECONDS"
      sleep 30
    retry
    end
    splitResults = result.split("\n")
    splitResults.each { |row|
      row.gsub!(/[\'|\"]/,'')
      match = row.match(goodRegex)
      if (match != nil) 
        goodData.write(SecureRandom.uuid + "\t" + match.to_a.drop(1).join("\t") + "\n")
      else
        limitedMatch = row.match(limitedRegex)
        limitedData.write(SecureRandom.uuid + "\t" + limitedMatch.to_a.drop(1).join("\t") + "\n")
        if (limitedMatch == nil )
          # count how many fail vs succeed
          puts row
          investigate.write(row)
        end 
      end
    } # end split results 
  }
end

pastFrom = Date.commercial(1899,1,1)
pastTo = Date.commercial(1996,1,1)
pastRange = pastFrom..pastTo
pastInterval = pastTo - pastFrom

# modernFrom = Date.commercial(2016,1,1)
# modernTo = Date.commercial(2016,52,1)
# modernRange = modernFrom..modernTo
# modernInterval = 7*2

futureFrom = Date.commercial(2019,1,2)
futureTo = Date.commercial(9920,1,1) # "oldest" contribution is in 12/31/9919
futureRange = futureFrom..futureTo
futureInterval = 7*52*1000

# candidate search is radio button 5
getContributions(5, pastRange, pastInterval, page, candidatesCSV, candidatesRegex, limitedCandidatesCSV, limitedCandidatesRegex, investigateCSV)
# getContributions(5, modernRange, modernInterval, page, candidatesCSV, candidatesRegex, limitedCandidatesCSV, limitedCandidatesRegex, investigateCSV)
getContributions(5, futureRange, futureInterval, page, candidatesCSV, candidatesRegex, limitedCandidatesCSV, limitedCandidatesRegex, investigateCSV)

# committee search is radio button 10
getContributions(10, pastRange, pastInterval, page, committeesCSV, committeesRegex, limitedCommitteesCSV, limitedCommitteesRegex, investigateCSV)
# getContributions(10, modernRange, modernInterval, page, committeesCSV, committeesRegex, limitedCommitteesCSV, limitedCommitteesRegex, investigateCSV)
getContributions(10, futureRange, futureInterval, page, committeesCSV, committeesRegex, limitedCommitteesCSV, limitedCommitteesRegex, investigateCSV)

candidatesCSV.close()
limitedCandidatesCSV.close()
committeesCSV.close()
limitedCommitteesCSV.close()
investigateCSV.close()