#!/bin/bash

input_file="emails.txt"
output_dir="results"

mkdir -p "$output_dir"

# Function to fetch country of IP
get_country() {
    local ip="$1"
    local country

    # Try ip-api first
    response=$(curl -m 5 -s "http://ip-api.com/json/$ip?fields=country")
    country=$(echo "$response" | jq -r '.country' 2>/dev/null)

    # Fallback: ipwho.is
    if [[ -z "$country" || "$country" == "null" ]]; then
        response=$(curl -m 5 -s "http://ipwho.is/$ip")
        country=$(echo "$response" | jq -r '.country' 2>/dev/null)
    fi

    # Fallback: ipinfo.io
    if [[ -z "$country" || "$country" == "null" ]]; then
        response=$(curl -m 5 -s "http://ipinfo.io/$ip")
        iso=$(echo "$response" | jq -r '.country' 2>/dev/null)
        if [[ "$iso" =~ ^[A-Z]{2}$ ]]; then
            country=$(curl -s "https://restcountries.com/v3.1/alpha/$iso" | jq -r '.[0].name.common' 2>/dev/null)
        fi
    fi

    [[ -z "$country" || "$country" == "null" ]] && country="Unknown"
    echo "$country"
}

# Loop through domains/emails
while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && continue

    if [[ "$line" == *"@"* ]]; then
        email="$line"
        domain=$(echo "$email" | awk -F'@' '{print $2}')
    else
        email=""
        domain="$line"
    fi

    # Get MX record
    mx=$(timeout 5 dig +short MX "$domain" | sort -n | head -n1 | awk '{print $2}' | sed 's/\.$//')
    if [[ -z "$mx" ]]; then
        echo "❌ No MX for $domain"
        continue
    fi

    # Get IP of MX
    ip=$(timeout 5 dig +short "$mx" | head -n1)
    if [[ -z "$ip" ]]; then
        echo "❌ No IP for $mx"
        continue
    fi

    # Get country (live lookup every time)
    country=$(get_country "$ip")
    echo "🌐 $domain ($ip) → $country"

    # Save into country folder
    mkdir -p "$output_dir/$country"

    echo "$domain | $mx | $ip" >> "$output_dir/$country/mx.txt"
    if [[ -n "$email" ]]; then
        echo "$email" >> "$output_dir/$country/emails.txt"
    fi

done < "$input_file"
