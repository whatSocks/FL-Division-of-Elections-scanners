# Florida Division of Elections scanners
These Ruby scripts scrape the Florida Division of Elections database for info on [political committees](http://election.dos.state.fl.us/committees/ComLkup.asp), [campaign donations](http://election.dos.state.fl.us/campaign-finance/contrib.asp) and [campaign expenses](http://election.dos.state.fl.us/campaign-finance/expend.asp).


# Getting Started 

## Install Dependencies

```
gem install bundler
bundle install
```

## Option 1: Straight to CSV

Run `ruby cmte_csv_generator.rb`, `ruby contrib_csv_generator.rb`, and `ruby exp_csv_generator.rb` to gather committee, contributor, and expense information.

## Option 2: Into a MySQL database

This project uses MySQL. 
If you don't have MySQL, download it here https://dev.mysql.com/downloads/mysql/

Once you have your MySQL up and running, create the following databases:

* `fl_cmte_list` for the committees 
* `fl_cmpgn_contrib` for the campaign contributors
* `fl_cmpgn_exp2` for expenditures

Take note of your `MYSQL_USERNAME`, `MYSQL_PASSWORD`, and your `MYSQL_HOST`. 
If you're running this project locally, your `MYSQL_HOST` will probably be `localhost`.

## Scraping the Data

Run the following commands to scrape the Florida Division of Elections site and collect the data, filling in your information as needed. 

```
ruby fl_div_elex_cmte_list_scanner.rb MYSQL_USERNAME MYSQL_PASSWORD MYSQL_HOST fl_cmte_list
ruby fl_div_elex_contrib_scanner.rb MYSQL_USERNAME MYSQL_PASSWORD MYSQL_HOST fl_cmpgn_contrib
ruby fl_div_elex_exp_scanner.rb MYSQL_USERNAME MYSQL_PASSWORD MYSQL_HOST fl_cmpgn_exp2
```
