sSiteCode = "VCR"
sMachine = "."
Set oCCMNamespace = GetObject("winmgmts://" & sMachine & "/root/ccm")
Set oInstance = oCCMNamespace.Get("SMS_Client")
Set oParams = oInstance.Methods_("SetAssignedSite").inParameters.SpawnInstance_()
oParams.sSiteCode = sSiteCode
