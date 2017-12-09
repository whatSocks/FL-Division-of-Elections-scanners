require 'rest_client'
require 'mechanize'

# Committee Information

cmte_list_file_url = 'http://election.dos.state.fl.us/committees/extractComList.asp'
rows = RestClient.get(cmte_list_file_url).split(/\r\n/)[1.. - 1]

cmte_list_file = File.open("output/cmte_list.csv", "w")
cmte_list_file.write("AcctNum Name  Type  TypeDesc  Addr1 Addr2 City  State Zip County  Phone ChrNameLast ChrNameFirst  ChrNameMiddle TrsNameLast TrsNameFirst  TrsNameMiddle")

rows.each { | row |
    cmte_list_file.write(row + "\n")
}
cmte_list_file.close()

