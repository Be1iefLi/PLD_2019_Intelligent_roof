import network, utime

start_time = utime.ticks_ms()

# ----------------------------------------------------------
# Define callback function used for monitoring wifi activity
# ----------------------------------------------------------
def wifi_cb(info):
    if (info[2]):
        msg = ", info: {}".format(info[2])
    else:
        msg = ""
    print("{} [WiFi] event: {} ({}){}".format(utime.ticks_diff(utime.ticks_ms(), start_time), info[0], info[1], msg))

# Enable callbacks
network.WLANcallback(wifi_cb)

# --------------------------------------------------------------------
# Create two WLAN objects
# one will be used in STA (Station) mode, one in AP (acces point mode)
# --------------------------------------------------------------------
print("\n=== Create WLAN instance objects ===\n")
sta_if = network.WLAN(network.STA_IF)
ap_if = network.WLAN(network.AP_IF)

# Start STA WiFi interface
print("\n=== Activate STA ===================\n")
sta_if.active(True)

# Connect to access point
print("\n=== Connect to access point ========\n")
sta_if.connect("306", "306dsdsg")

# Wait until connected and show IF config
tmo = 50
while not sta_if.isconnected():
    utime.sleep_ms(100)
    tmo -= 1
    if tmo == 0:
        break
print("\n=== STA Connected ==================\n")
sta_if.ifconfig()

# Start ftp server
print("\n=== Start Ftp server ===============\n")
network.ftp.start()
# Wait until started
tmo = 50
while network.ftp.status()[0] != 2:
    utime.sleep_ms(100)
    tmo -= 1
    if tmo == 0:
        break
# Get FTP server status
# FTP listens on Station IP
utime.sleep_ms(100)
network.ftp.status()

# Get STA WiFi interface configuration
print("\n=== STA configuration ==============\n")
sta_if.config('all')

# Start AP WiFi interface
print("\n=== Activate AP ====================\n")
ap_if.active(True)

# Wait until started and show IF config
# We don't need to check for connected clients
# so we give the False argument
tmo = 50
while not ap_if.isconnected(False):
    utime.sleep_ms(100)
    tmo -= 1
    if tmo == 0:
        break
print("\n=== AP started =====================\n")
ap_if.ifconfig()

# Wait until STA reconnected
tmo = 50
while not sta_if.isconnected():
    utime.sleep_ms(100)
    tmo -= 1
    if tmo == 0:
        break
print("\n=== STA ReConnected ================\n")
sta_if.ifconfig()

# Get AP WiFi interface configuration
print("\n=== AP configuration ===============\n")
ap_if.config('all')

# Get FTP server status
# FTP now listens on Station IP and AP IP
# Wait until activated after WiFi mode change
print("\n=== Ftp server status ==============\n")
tmo = 50
while network.ftp.status()[0] != 2:
    utime.sleep_ms(100)
    tmo -= 1
    if tmo == 0:
        break
utime.sleep_ms(100)
network.ftp.status()

utime.sleep(2)

# Change some AP parameters
# AP will stop than started with new parameters
print("\n=== Change AP parameters ===========\n")
ap_if.config(essid='ESP32_LoBo', authmode=network.AUTH_WPA_WPA2_PSK, password='12345678')

utime.sleep_ms(200)
# Wait until started and show IF config
# We don't need to check for connected clients
# so we give the False argument
tmo = 50
while not ap_if.isconnected(False):
    utime.sleep_ms(100)
    tmo -= 1
    if tmo == 0:
        break
print("\n=== AP ReStarted ===================\n")
ap_if.config('all')

utime.sleep(5)

# Stop STA interface
print("\n=== Stop STA interface =============\n")
sta_if.active(False)

utime.sleep(1)
# Get FTP server status
# FTP now listens only on AP IP
print("\n=== Ftp server status ==============\n")
network.ftp.status()

# Stop AP interface
# WiFi will be stopped
print("\n=== Stop AP interface ==============\n")
ap_if.active(False)

utime.sleep(1)
# Get FTP server status
# FTP is now disabled, as no WiFi interface is active
print("\n=== Ftp server status ==============\n")
network.ftp.status()

# Check WiFi status
print("WiFi active: {}".format(network.WLAN().wifiactive()))
