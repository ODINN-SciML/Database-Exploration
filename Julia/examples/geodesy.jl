

# Playing with coodinate projection 

using Geodesy

projection = LLAfromUTMZ(wgs84)

x_bossom = UTMZ(-682.471, 5.1912e6, 0.0, 31,true)

tm = Geodesy.TransverseMercator(WGS84)

x₀ = 10.1335
x = -682.471
y = 5.1912e6

Geodesy.transverse_mercator_reverse(x₀, x, y , 0.9996, tm)


###
using Unitful: m, rad, °
using CoordRefSystems

k₀ = 0.9996

# xₒ = 500000.0m
xₒ = 0.0m
yₒ = 0.0m
# yₒ = hemisphere == :north ? 0.0m : 10000000.0m

lonₒ = 8.01919°
# lonₒ = 10.1335°
latₒ = 0.0°


S = CoordRefSystems.Shift(; lonₒ, xₒ, yₒ)

x = -8040.94
y = 5.15794e6
x_glacier = TransverseMercator{k₀,latₒ,datum,S}(x, y)

convert(LatLon, x_glacier)

# Clean for each glacier

k₀ = 0.9996
xₒ = 0.0m
yₒ = 0.0m

# Aletschgletscher

lonₒ = 8.01919°
latₒ = 0.0°
x = -8040.94
y = 5.15794e6
S = CoordRefSystems.Shift(; lonₒ, xₒ, yₒ)
x_glacier = TransverseMercator{k₀,latₒ,WGS84Latest,S}(x, y)

convert(LatLon, x_glacier)
# Answer: Lat = 46.574977403312715°, Lon = 7.914252983649885° (correct for upper left corner)

# Bossons 
lonₒ = 10.1335°
latₒ = 0.0°
x = -682.471
y = 5.1912e6
S = CoordRefSystems.Shift(; lonₒ, xₒ, yₒ)
x_glacier = TransverseMercator{k₀,latₒ,WGS84Latest,S}(x, y)

convert(LatLon, x_glacier)
# Answer: Lat = 46.874338533298065°, Lon = 10.124544115391744°


# Glacier d’Argentière
lonₒ = 6.985°
latₒ = 0.0°
x = -3574.0
y = 5.09221e6
S = CoordRefSystems.Shift(; lonₒ, xₒ, yₒ)
x_glacier = TransverseMercator{k₀,latₒ,WGS84Latest,S}(x, y)

convert(LatLon, x_glacier)
# Answer: Lat = 45.98345259928449°, Lon = 6.938857312258543