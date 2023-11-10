using DrWatson
@quickactivate "diff_gleam"
using PyCall
# xr = pyimport("xarray")
# ds = xr.open_dataset(projectdir("forcing_3hourly_UTC.nc"))
icoscp_auth = pyimport("icoscp.cpauth.authentication")
icoscp_dobj = pyimport("icoscp.cpb.dobj")
icoscp_station = pyimport("icoscp.station.station")
icoscp_auth.Authentication(token = "cpauthToken=WzE2OTk3MDg1NTU3NDQsIm9saXZpZXIuYm9udGVAdWdlbnQuYmUiLCJPcmNpZCJdHmHpTZQoqTasoEEsaqOs5kuJmcrzVUk/zb5xKXKFd5fdZ0u/zlnwgTUc73GkwwlXkEUJiSKg7/W4kDM/OgEtamNTyUtVqvbgrSR55TUPG3RLzfOBhoYB/PYhP5B3Kc2CqN3n7o9vlaEuYZ6dvqxq73bbkUfQI/u2J8tvfIb4Lvujr2vTovJiMfgZJuMPFdwlsrkTBQkFrGIr3dZFRbcydg/jw3WbnXFZmcrQmyZTSudwM7qMjwn/dO4PotlPHind0PLRWce/nd96RWxGHgZexFzTcqKj0DdgjcNRjf/u4FLHGDzgfCu0sOQPmMpTfuGTsqtPPpKkBuiLQp6nGlj/a5w=")

station_code = "ES-LM1"
myStation = icoscp_station.get(station_code)
py"""
import xarray as xr
xr.open_dataset("../../forcing_3hourly_UTC.nc")

"""
