using HTTP, CSV, DataFrames
using Dates, Plots, Polynomials

api_key = "Z5K9YLTH7W82B0JQ"
query_string = "https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=SPY&outputsize=full&datatype=csv&apikey=$api_key"
data = HTTP.get(query_string).body |>
            String |>
            IOBuffer |>
            CSV.File |>
            DataFrame;

data.unix_timestamp = data.timestamp .|> DateTime .|> datetime2unix
data.log_close= log.(data.close)
data_fit = fit(data.unix_timestamp, data.log_close, 1)
data.adjusted_log_close = data.log_close .- data_fit.(data.unix_timestamp)
data.year_adjusted_log_close = data.adjusted_log_close ./ 0.075;

# helper function to add any events to the plot
function add_event(date::String, name::String, position::Int)
    event_date = Date(date, "yyyy-mm-dd")
    vline!([event_date], color=:green, linestyle=:dash, label=false)
    annotate!(event_date, position, text(name))
end

latest_plot = plot(data.timestamp, data.year_adjusted_log_close, label=false, size=(1600,800))

# Add special events to the plot
add_event("2009-05-01", "2009\nFinancialCrisis", 8)
add_event("2020-02-01", "COVID-19", 8)
add_event("2022-02-21", "R-U-War", 7)
add_event("2023-01-06", "BUY-UPRO", 8)

# Add lines represent how many years the price is ahead or behind
date_annotate = Date("2000-01-01", "yyyy-mm-dd")
hline!([0], label=false, color=:red, linestyle=:dash)
annotate!(date_annotate, 0, text("S&P500 Base Line"))
hline!([2], label=false, color=:red, linestyle=:dash)
annotate!(date_annotate, 2, text("2 years ahead"))
hline!([-2], label=false, color=:red, linestyle=:dash)
annotate!(date_annotate, -2, text("2 years behind"))

# Add current price position with rounded year value
scatter!([data.timestamp[1]], [data.year_adjusted_log_close[1]], label=false, color=:red, markershape=:circle)
annotate!(data.timestamp[1], data.year_adjusted_log_close[1]+0.5, text("$(round(data.year_adjusted_log_close[1], digits=2))"))

# Save plot to file before display
file_name = "results/"*Dates.format(now(), "yyyy-mm-dd")*".png"
isfile(file_name) && rm(file_name)
savefig(latest_plot, file_name);

# display(latest_plot)