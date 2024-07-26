#!/bin/bash
# File: capture_and_extract_urls.sh

# Install necessary packages
echo "Installing necessary packages..."
sudo apt-get update
sudo apt-get install -y tcpdump tshark gawk

# Define paths relative to HOME
PCAP_FILE="$HOME/traffic.pcap"
HTTP_FILE="$HOME/http_urls.txt"
DNS_FILE="$HOME/dns_queries.txt"
FTP_FILE="$HOME/ftp_commands.txt"
ALL_URLS_FILE="$HOME/all_urls.txt"
FILTERED_URLS_FILE="$HOME/filtered_urls.txt"
UNIQUE_URLS_FILE="$HOME/unique_urls.txt"

# Capture network traffic
sudo tcpdump -i any -s 0 -w $PCAP_FILE

# Extract HTTP/HTTPS URLs
tshark -r $PCAP_FILE -Y "http.request" -T fields -e http.host -e http.request.uri > $HTTP_FILE

# Extract DNS queries
tshark -r $PCAP_FILE -Y "dns" -T fields -e dns.qry.name > $DNS_FILE

# Extract FTP commands
tshark -r $PCAP_FILE -Y "ftp.request.command" -T fields -e ftp.request.command -e ftp.request.arg > $FTP_FILE

# Combine and clean URLs
cat $HTTP_FILE $DNS_FILE $FTP_FILE > $ALL_URLS_FILE
sort $ALL_URLS_FILE | uniq > $UNIQUE_URLS_FILE

echo "Unique URLs and domains have been extracted and saved to $UNIQUE_URLS_FILE"
