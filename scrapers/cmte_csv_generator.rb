require 'rest_client'
require 'mechanize'

# Committee Information

cmte_list_file_url = 'http://election.dos.state.fl.us/committees/extractComList.asp'
#http://dos.elections.myflorida.com/committees/ComLkupByName.asp -> might be a better source
rows = RestClient.get(cmte_list_file_url).split(/\r\n/)[1.. - 1]

cmte_list_file = File.open("output/cmte_list.csv", "w")
cmte_list_file.write("AcctNum Name\tType\tTypeDesc\tAddr1\tAddr2\tCity\tState\tZip\tCounty\tPhone\tChrNameLast\tChrNameFirst\tChrNameMiddle\tTrsNameLast\tTrsNameFirst\tTrsNameMiddle")

rows.each { | row |
	#todo: fill with placeholder if field is empty
	#todo: "No Chairman" -> turn to placeholder
	#todo: figure out what to do with people with no middle name (since they might have middle names)
    cmte_list_file.write(row + "\n")
}
cmte_list_file.close()

