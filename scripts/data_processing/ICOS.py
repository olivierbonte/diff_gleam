import os
from pathlib import Path
from icoscp.station import station
from icoscp.cpb.dobj import Dobj
from icoscp.cpauth.authentication import Authentication
Authentication(token = "cpauthToken=WzE2OTk3MDg1NTU3NDQsIm9saXZpZXIuYm9udGVAdWdlbnQuYmUiLCJPcmNpZCJdHmHpTZQoqTasoEEsaqOs5kuJmcrzVUk/zb5xKXKFd5fdZ0u/zlnwgTUc73GkwwlXkEUJiSKg7/W4kDM/OgEtamNTyUtVqvbgrSR55TUPG3RLzfOBhoYB/PYhP5B3Kc2CqN3n7o9vlaEuYZ6dvqxq73bbkUfQI/u2J8tvfIb4Lvujr2vTovJiMfgZJuMPFdwlsrkTBQkFrGIr3dZFRbcydg/jw3WbnXFZmcrQmyZTSudwM7qMjwn/dO4PotlPHind0PLRWce/nd96RWxGHgZexFzTcqKj0DdgjcNRjf/u4FLHGDzgfCu0sOQPmMpTfuGTsqtPPpKkBuiLQp6nGlj/a5w=")
station_code = "ES-LM1" #Majadas del Tietar North
myStation = station.get(station_code)
print(f"\n{myStation.info()}\n")
myStationData = myStation.data()

#2 product available: Fluxnet and Fluxnet Archive but only Fluxnet works
uri = myStationData[myStationData["specLabel"] == "Fluxnet Product"]["dobj"].values[0]
print(f"\n{uri}\n")
ES_LM1_dobj = Dobj(uri)
data_ES_LM1 = ES_LM1_dobj.data
data_ES_LM1 = data_ES_LM1.rename(columns = {"TIMESTAMP":"time"})
data_ES_LM1 = data_ES_LM1.set_index("time")
data_dir = Path("../../data/exp_raw/ICOS")
if not os.path.exists(data_dir):
    os.makedirs(data_dir)
data_ES_LM1.to_csv(data_dir/"ICOS_FLUXNET_ES_LM1.csv")