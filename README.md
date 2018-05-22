# Florida Division of Elections Scanners

note:This is a side project and not as rigorous as it should be, yet. 

These Ruby scripts scrape the Florida Division of Elections database for info on [campaign contributions](http://election.dos.state.fl.us/campaign-finance/contrib.asp). 
Shoutout to the [Palm Beach Post](https://www.palmbeachpost.com/) for starting this project. 

*For a good time, point the scraper to collect contributions between the year 9000 and 10,000.*

[Political committees](http://election.dos.state.fl.us/committees/ComLkup.asp) and [campaign expenses](http://election.dos.state.fl.us/campaign-finance/expend.asp) are a work in progress.

# Getting Started 

## Assuming you have Ruby, install Dependencies

```
gem install bundler
bundle install
```

## Option 1: Straight to CSV

Run `ruby scrapers/contrib_csv_generator.rb` to gather contribution information. 

The data will be organized for easy import into a Neo4j database, but you can naturally modify the output as you wish. 

## Option 2: Into a Neo4j database

After importing the data to CSV, import it using the Neo4j import tool, then use `$NEO4J_HOME/bin/neo4j console` to start the database.

```
$NEO4J_HOME/bin/neo4j-admin import --ignore-duplicate-nodes=true --ignore-extra-columns=true --id-type=STRING  --delimiter="\t" --ignore-missing-nodes --nodes:Candidate headers/candidateNodeHeader.csv,output/candidates.* --nodes:Committee headers/committeeNodeHeader.csv,output/committees.* --nodes:Contribution headers/contributionCo.csv,output/committees.*  --nodes:Contribution headers/contributionCa.csv,output/candidates.*  --nodes:Contributor headers/contributorCa.csv,output/candidates.* --nodes:Contributor headers/contributorCo.csv,output/committees.* --relationships:CONTRIBUTED headers/contributedCa.csv,output/candidates.* --relationships:CONTRIBUTED headers/contributedCo.csv,output/committees.* --relationships:SUPPORTS headers/supportsCo.csv,output/committees.* --relationships:SUPPORTS headers/supportsCa.csv,output/candidates.*
```

### Nodes

* Contributor
* Candidate
* Contribution
* Committee

### Relationships

* SUPPORTS
* CONTRIBUTED

# Sample queries

## Who/what contributed the most (in dollars), and to who?

The query below assumes a `Party` node and a `BELONGS_TO` relationship. 
First, create the relationship:

```
MATCH (candidate:Candidate)
MERGE (candidate)-[:BELONGS_TO]->(p:Party)
SET p.name = c.party
```

Then run the query

```
MATCH (contributor:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)-[:BELONGS_TO]->(party:Party)
RETURN contributor.name, count(c) AS count, sum(c.amount) AS amount, collect(distinct candidate.name), collect(distinct party.name) AS Party, collect(distinct c.year)
ORDER BY AMOUNT DESC
LIMIT 10
```

## Who contributed the most (in number of contributions), and to who?

```
MATCH (contributor:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)-[:BELONGS_TO]->(party:Party)
RETURN contributor.name, count(c) AS count, sum(c.amount) AS amount, collect(distinct candidate.name), collect(distinct party.name) AS Party, collect(distinct c.year)
ORDER BY COUNT DESC
LIMIT 10
```

## What city made the most contributions, and to who?

```
MATCH (contributor:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)-[:BELONGS_TO]->(party:Party)
WITH c.city AS city, count(distinct contributor) AS contributors, count(c) AS contributions, collect(distinct party.name) AS party
RETURN city, contributors, contributions, party
ORDER BY contributions DESC
LIMIT 10
```

## How do the big names play the field?

Try searching for names that contain `GEO GROUP` or variations of `AT&T`

```
MATCH (geo:Contributor)-->(c:Contribution)-[:SUPPORTS]->(candidate:Candidate)
WHERE geo.name CONTAINS "AT&T" OR geo.name contains "AT &T"
RETURN collect(distinct geo.name), candidate.party AS party, count(distinct candidate.name) AS candidates, sum(c.amount) AS amount
```