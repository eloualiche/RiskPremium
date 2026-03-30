# src/FredUtils.jl
module FredUtils

using HTTP, JSON, DataFrames, Dates

export fred_series_info, fred_observations

const FRED_BASE = "https://api.stlouisfed.org/fred"

function _api_key()
    key = get(ENV, "FRED_API_KEY", "")
    if isempty(key)
        envfile = joinpath(@__DIR__, "..", ".env")
        if isfile(envfile)
            for line in eachline(envfile)
                m = match(r"^FRED_API_KEY\s*=\s*(.+)$", line)
                if m !== nothing
                    key = strip(m.captures[1])
                    break
                end
            end
        end
    end
    isempty(key) && error("Set FRED_API_KEY environment variable or add it to .env")
    return key
end

"""
    fred_series_info(series_id) -> NamedTuple

Return metadata for a FRED series: title, frequency, units, seasonal_adjustment,
observation_start, observation_end.
"""
function fred_series_info(series_id::AbstractString)
    url = "$FRED_BASE/series?series_id=$series_id&api_key=$(_api_key())&file_type=json"
    resp = HTTP.get(url)
    data = JSON.parse(String(resp.body))
    s = data["seriess"][1]
    return (
        id              = s["id"],
        title           = s["title"],
        frequency       = s["frequency"],
        units           = s["units"],
        seasonal_adjustment = s["seasonal_adjustment"],
        observation_start = Date(s["observation_start"]),
        observation_end   = Date(s["observation_end"]),
    )
end

"""
    fred_observations(series_id; start_date, end_date) -> DataFrame

Download observations for a FRED series. Returns DataFrame with columns `date::Date`
and `value::Union{Float64,Missing}`.
"""
function fred_observations(series_id::AbstractString;
        start_date::Date = Date(1947,1,1),
        end_date::Date   = Date(2026,12,31))
    url = string(FRED_BASE, "/series/observations?series_id=", series_id,
        "&api_key=", _api_key(),
        "&file_type=json",
        "&observation_start=", start_date,
        "&observation_end=", end_date)
    resp = HTTP.get(url)
    data = JSON.parse(String(resp.body))
    obs_list = data["observations"]
    n = length(obs_list)
    dates  = Vector{Date}(undef, n)
    values = Vector{Union{Float64,Missing}}(undef, n)
    for (i, obs) in enumerate(obs_list)
        dates[i] = Date(obs["date"])
        v = obs["value"]
        values[i] = v == "." ? missing : parse(Float64, v)
    end
    return DataFrame(date = dates, value = values)
end

end # module
