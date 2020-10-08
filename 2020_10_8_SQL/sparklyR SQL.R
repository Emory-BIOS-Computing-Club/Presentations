
### TOPIC: A Brief Intro of SQL on sparklyr
### DATE: 10/8/2020
### SPEAKER: GAVIN T.


### Aims of this talk and next:

### Today:
### 1. Connect to Spark from R. The sparklyr package provides a complete dplyr and SQL backend.
### 2. Filter and aggregate Spark datasets using SQL then bring them into R for analysis and visualization.


### Maybe Next time:
### 3. Use Spark's distributed machine learning library from R.
### 4. Create customized distributed machine learning module in Spark.


###########################################################################################
###                   PART-I Install & connect to sparklyr on your local PC
###########################################################################################

### You can install the sparklyr package from CRAN as follows:
install.packages("sparklyr")

### You should also install a local version of Spark for development purposes:
library(sparklyr)
spark_install(version = "2.4.6") # The version of spark. 



### You can connect to both local instances of Spark as well as remote Spark clusters. 
### Here we'll connect to a local instance of Spark via the spark_connect function:

sc <- spark_connect(master = "local")

library(dplyr)
iris_tbl <- copy_to(sc, iris)
mtcars_tbl <- copy_to(sc, mtcars)

### The returned Spark connection (sc) provides a remote dplyr data source to the Spark cluster.

### For more information on connecting to remote Spark clusters see the Deployment section of the sparklyr website.
### https://spark.rstudio.com/deployment/

### For more details on Spark:
### https://spark.apache.org/


### For a nice cheat-sheet of sparklyr:
### https://science.nu/wp-content/uploads/2018/07/r-sparklyr.pdf

###########################################################################################
###                   PART-II Basic SQL data manipulation on sparklyr
###########################################################################################


### 1. SELECT: Suppose we want to show all the contents of the dataset:

### A more `Sparky' kind of way (fast, things stay on spark cluster, recommend):
### The generated result is a `formula' based on your original data tables.
iris_all<-sdf_sql(sc,"SELECT * FROM iris")
iris_all

iris_all_tbl=collect(iris_all) # you can `download` the data from spark to R later

### Or a more R kind of approach (Will get everything to R from spark,
### !!!quickly deplete your local mem if tabel is large!!!)
library(DBI)

iris_all<-dbGetQuery(sc, "SELECT * FROM iris")
iris_all


###  Suppose we want to keep only some columns:

iris_sub<-sdf_sql(sc, "SELECT Sepal_Length,Sepal_Width, Petal_Length AS PL,
                              Petal_Width AS PW  
                       FROM iris") 
iris_sub


### 2. SELECT DISTINCT: Suppose we want to show all the unique species:

unique_species<-sdf_sql(sc, "SELECT DISTINCT Species FROM iris") 
unique_species

### or, we want to know the distinct number of cylinders in mtcars

unique_cyl<-sdf_sql(sc, "SELECT DISTINCT cyl FROM mtcars") 
unique_cyl


### 3. WHERE: Suppose we want to filter all the contents of the dataset to a subgroup of records:

iris_sub=sdf_sql(sc, "SELECT * FROM iris WHERE Species=='setosa' ") 
iris_sub

### or:

iris_sub=sdf_sql(sc, "SELECT * FROM iris WHERE Species NOT IN ('versicolor','virginica') ") 
iris_sub

### or we want to see those 'setosa' and Sepal_Length<4.5
iris_sub=sdf_sql(sc, "SELECT * FROM iris WHERE Sepal_Length<4.5 AND Species=='setosa' ") 
iris_sub

### or we want to see those 8 cylinder cars or cars has hp>150
mtcars_sub=sdf_sql(sc, "SELECT * FROM mtcars WHERE cyl==6 OR hp>150 ") 
mtcars_sub

### 4. ORDER BY: sort cars in descending order by hp then by ascending wt
mtcars_sub=sdf_sql(sc, "SELECT * FROM mtcars ORDER BY hp desc, wt ") 
mtcars_sub

### 5. COUNT all the different cars, and get the mean hp GROUP BY cyl then ORDER BY cyl descending
mtcars_agg=sdf_sql(sc, "SELECT COUNT(*) AS counts, AVG(hp) AS avg_hp  FROM mtcars GROUP BY cyl ") 
mtcars_agg

mtcars_agg=sdf_sql(sc, "SELECT cyl, COUNT(*) AS counts, AVG(hp) AS avg_hp  FROM mtcars GROUP BY cyl ORDER BY cyl DESC ") 
mtcars_agg

### SUM up the counts using subquery

mtcars_agg=sdf_sql(sc, "SELECT SUM(counts) FROM (SELECT cyl, COUNT(*) AS counts, AVG(hp) AS avg_hp  
                                                  FROM mtcars GROUP BY cyl ORDER BY cyl DESC )") 
mtcars_agg

##### Leetcode: Q1 ############################################################


# Write a SQL query to find all duplicate emails in a table named Person.
# 
#   +----+---------+
#   | Id | Email   |
#   +----+---------+
#   | 1  | a@b.com |
#   | 2  | c@d.com |
#   | 3  | a@b.com |
#   +----+---------+
#   For example, your query should return the following for the above table:
#   
#   +---------+
#   | Email   |
#   +---------+
#   | a@b.com |
#   +---------+
#   Note: All emails are in lowercase.

Person<-data.frame("Id" = 1:3, "Email"=c("a@b.com","c@d.com","a@b.com") )
Person_tbl<-copy_to(sc,Person)


sdf_sql(sc, "SELECT Email FROM (SELECT Email, COUNT(*) AS counts FROM person GROUP BY Email)  WHERE counts>1")


### 6. UNION go to:  https://www.w3schools.com/sql/sql_union.asp
### For more details

### 7. JOIN: (inner left right outer, hard to describ here) go to:  https://www.w3schools.com/sql/sql_join.asp 
### For more details




##### Leetcode: Q3 ############################################################

# Table: Person
# 
#   +-------------+---------+
#   | Column Name | Type    |
#   +-------------+---------+
#   | PersonId    | int     |
#   | FirstName   | varchar |
#   | LastName    | varchar |
#   +-------------+---------+
#   PersonId is the primary key column for this table.
# Table: Address
# 
#   +-------------+---------+
#   | Column Name | Type    |
#   +-------------+---------+
#   | AddressId   | int     |
#   | PersonId    | int     |
#   | City        | varchar |
#   | State       | varchar |
#   +-------------+---------+
#   AddressId is the primary key column for this table.
# 
# 
# Write a SQL query for a report that provides the following information for each person in the Person table, regardless if there is an address for each of those people:
#   
#   FirstName, LastName, City, State