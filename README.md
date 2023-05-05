# SQLREPORT

This code is an example of PostgreSQL code for the class D191 at WGU.
It shows the creation of tables Detailed and Summary, filling the detailed
table with joins, a function that fills plus transforms data based on a stored 
procedure. The logic on this transformation is based on the idea that with the 
given date, any date before it is considered a late return and will produce either
a boolean value based on that information.

This code has a trigger that has it all run together when the detailed table
acquires a new insert.
