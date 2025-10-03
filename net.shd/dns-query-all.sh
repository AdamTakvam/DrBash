#!/bin/bash

source "${DRB_LIB:-${HOME}/lib}/general.sh"
Require bind9-dnsutils

APPNAME="dns-query-all"

PrintHelp() {
  tabs 4
  echo "Query the authoritative name server for as many records as possible related to the specified domsin."
  echo
  echo "Usage: $APPNANME [FLAGS] DOMAIN [NAMESERVER]"
  echo
  echo "FLAGS:\t(optional) Operational flags"
  echo -e "\t-x\t\tExtended search for common subdomains."
  echo -e "\t-h\t\tDisplay this help text."
  echo -e "\t-q <type>\tType of query to perform."
  echo -e "\t\t?\t will return a list of oquery options (default: \"any\")."
  echo -e "\t-v\t\tVerbose output"
  echo -e "\t-vv\t\tSimulation mode: Prints commands that would be executed."
  echo
  echo -e "DOMAIN\tThe domain for which you want to query DNS records."
  echo -e "NAMESERVER\t(optional) Override automatic name server selection."
  echo
}

QueryHelp() {
  tabs 4
  echo
  echo -e "DNS Query/Record Types:"
  echo -e "\t*\t\t\"ALL\": Request all records for a domain."
  echo -e "\t\t\t\tDoes not include subdomains."
  echo -e "\t\t\t\tOften not supported/honored."
  echo -e "\t\t\t\tUnsupported on: CloudFlare, Namecheap"
  echo -e "\tAXFR\tDomain transfer request. Returns *all* DNS information for a domain and subdomains."
  echo -e "\t\t\t\tMust be a registrar. Requires secret domain transfer key"
  echo -e "\t\t\t\tSTILL not always supported!"
  echo -e "\tA\t\tHosts (IPv4)."
  echo -e "\tAAAA\tHosts (IPv6)."
  echo -e "\tCNAME\tSubdomains and redirects to other domains."
  echo -e "\tALIAS\tAliases can point to full URLs with path, not just other (sub)domains."
  echo -e "\tURI\t\tURI/Hostname Redirect. Differences between URI and ALIAS types are very subtle."
  echo -e "\tTXT\t\tMiscellaneous keys / site validation."
  echo -e "\tMX\t\tEmail server info."
  echo -e "\tCERT\tSite Certificate."
  echo -e "\tCAA\t\tAcceptable Certificate Authorities for a domain."
  echo -e "\tSOA\t\tStart Of Authority - The IP of the domain registrar."
  echo -e "\tNS\t\tAuthoritative name server(s)."
  echo -e "\tSRV\t\tService: Used to advertise the location of various services. Like your Minecraft, Discord, or Plex servers, for example."
  echo -e "\tHINFO\tReturned by hosts who want you to fuck off with your \"any\" query. Seriously. That's what this record type is for!"
  echo -e "\tPTR\t\tUsed for reverse DNS lookups."
  echo -e "\tRP\t\tResponsible Person: Admin contact info. Seldom used or accurate."
  echo -e "\tSSHFP\tSSH public key. Used to automatically verify incoming users from a given domain."
  echo
  echo "No, this list is actually far from exhaustive. The especially-useless record types have been filtered out for you. You're welcome!"
  echo "A complete list can be found at: https://e.wikipedia.org/wiki/List_of_DNS_record_types"
}

declare -ar COMMON_SUBDOMAINS=(www mail mx a.mx smtp pop imap blog en ftp ssh login members)

declare -u query='*'
declare -l domain dns

# Parse parameters
while [ "$1" ]; do 
  case "$1" in
    -h) PrintHelp; exit 0 ;;
    -x) ext=y; shift ;;
    -q) query="$2"; shift 2 
        [ "$query" == "?" ] && { QueryHelp; exit 0; } ;;
    -vv) LogEnableDebug; shift ;;
    -v) LogEnableVerbose; shift ;;
    -*) LogError "$(ColorText LRED "Invalid flag: $1\n")"; PrintHelp; exit 1 ;;
    *)  [ "$domain" ] && dns="$1" || domain="$1"; shift ;;
  esac
done

[ "$domain" ] && Log "Domain: $domain" || { PrintHelp; exit 1; }

[ "$dns" ] || dns="$(Run -u dig +short SOA "$domain" | awk '{print $1}')"
Log "Name Server: ${dns:-default}"
dns=${dns:+@$dns} # Translation: If $dns != "", then return $dns prefixed with an @ character

Log "Query: $query"

if [ "$ext" ]; then
  Log "Performing extended lookups:"
  
  Run -u dig +nocmd $dns "$domain" +noall +answer $query
  
  wild_ips=$(Run -u dig +short $dns "*.$domain" $query | tr '\n' '|')
  wild_ips="${wild_ips%|}"
  LogDebug "wild_ips = $wild_ips"

  for sub in "${COMMON_SUBDOMAINS[@]}"; do
    Run -u dig +nocmd $dns "$sub.$domain" +noall +answer $query
  done # | cat  #grep -vE "${wild_ips}"
  Run -u dig +nocmd $dns "*.$domain" +noall +answer $query
else
  resp="$(Run -u dig +nocmd $dns "$domain" +noall +answer "$query")"
  [ "$resp" ] && Log "$resp" || LogError "$(ColorText LRED "> Name server returned null result for $query query.")"
fi
