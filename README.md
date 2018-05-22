* excluding data with bad addresses (approx) x% for contributions to committees and x% for contributions to candidates
* inspired by work from the Palm Beach Post
* negative numbers -> returned checks
* interesting bad data: contributions made in the future, contributions made pre-internet
* interesting data: negative numbers - what candidates *returned* the most money

Who/what contributed the most in 2016 (in dollars), and to who?

match (contributor:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)-[:BELONGS_TO]->(party:Party)
return contributor.name, count(c) as count, sum(c.amount) as amount, collect(distinct candidate.name), collect(distinct party.name) as Party, collect(distinct c.year)
order by amount desc
limit 10

Who contributed the most in 2016 (in number of contributions), and to who?

match (contributor:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)-[:BELONGS_TO]->(party:Party)
return contributor.name, count(c) as count, sum(c.amount) as amount, collect(distinct candidate.name), collect(distinct party.name) as Party, collect(distinct c.year)
order by count desc
limit 10


What city made the most contributions in 2016, and to who?

match (contributor:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)-[:BELONGS_TO]->(party:Party)
with c.city as city, count(distinct contributor) as contributors, count(c) as contributions, collect(distinct party.name) as party
return city, contributors, contributions, party
order by contributions desc
limit 10

How do the big names play the field?
match (geo:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)
where geo.name contains "AT&T" OR geo.name contains "AT &T"
return collect(distinct geo.name), candidate.party as party, count(distinct candidate.name) AS candidates, sum(c.amount) as amount


Find people similar to me in my city
match (scott:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)
where scott.name includes "GEO"
WITH collect(candidate.name) AS candidates, scott
optional match (other:Person)-->(contributions:Contribution)-[:RECEIVED]->(candidate), (contributions)-[:IN_CITY]->(city:City {name:"BOCA RATON"})
WHERE candidate.name in candidates
AND scott <> other
return other.name as contributor, count(contributions) AS contributions, collect(distinct candidate.name) as candidates, collect(distinct city.name) as cities, count(distinct candidate) as `similarity to you`, collect(distinct contributions.year) as years
ORDER BY `similarity to you` desc
limit 10


# Florida Division of Elections scanners
These Ruby scripts scrape the Florida Division of Elections database for info on [political committees](http://election.dos.state.fl.us/committees/ComLkup.asp), [campaign donations](http://election.dos.state.fl.us/campaign-finance/contrib.asp) and [campaign expenses](http://election.dos.state.fl.us/campaign-finance/expend.asp).


# Getting Started 

## Install Dependencies

```
gem install bundler
bundle install
```

## Option 1: Straight to CSV

Run `ruby scrapers/cmte_csv_generator.rb`, `ruby scrapers/contrib_csv_generator.rb`, and `ruby scrapers/exp_csv_generator.rb` to gather committee, contributor, and expense information.

## Option 2: Into a Neo4j database

Import steps: 
* run the scrapers to generate CSVs with the intiial data
* use neo4j-import tool to import the data into a new database
* use a driver to query the datasets and import more (new) data as time passes