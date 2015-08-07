# Crealytics
Technical test - Emanuel  Comsa

#Explanation
The current script reads a CSV with multiple columns. The columns are defined in the class constants. From the fact that it uses a combiner class, I assumed that at any point a bach of csv's need to be merged using a unique column. I think you have multiple CSV types for each customer/campaign and you need to make a single CSV with all the data. Maybe multiple exports from a third party source.
The script checks a folder for the files that matche the name inputed and then sorts them by the date parsed from the file name.
Since your code initially had only one file as a param for the combine method from the Combiner class, I assumed that i could work for now with just one CSV source, so i created one for tests.
You create a hash with the keys being the headers of the CSV files and the values being an array of all the values.
You now have an enumerator with as many elements as there are lines in the CSV.
Then, for each of the elements in the enumerator, you output it into the destination CSV, making sure you divide the total rows using the LINES_PER_FILE value.
You used the combine_values method to change some of the values depending on calculations needed by the business logic.

I added my own file, app.rb with the changes while leaving the modifier.rb file intact. There are not many changes as I believe the current code is working pretty okay for what I understood it has to do.