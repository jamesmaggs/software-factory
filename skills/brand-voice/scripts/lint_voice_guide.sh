#!/usr/bin/env bash
#
# lint_voice_guide.sh
#
# Deterministic checker for a finished brand voice guide. It enforces the fixed
# output contract that downstream design tools and AI agents rely on, so the
# schema is guaranteed rather than merely promised by the prose instructions.
#
# Usage:
#   bash lint_voice_guide.sh path/to/brand-voice-guide.md
#
# Exit codes:
#   0 = clean (warnings allowed)
#   1 = one or more errors
#   2 = file unreadable / no argument
#
# Implementation note: the U+2192 arrow (→) is normalised to "->" with sed
# before parsing, so the awk program stays ASCII and portable across awks.

set -u

if [ "$#" -ne 1 ]; then
  echo "Usage: bash lint_voice_guide.sh path/to/brand-voice-guide.md"
  exit 2
fi

FILE="$1"
if [ ! -r "$FILE" ]; then
  echo "Could not read file: $FILE"
  exit 2
fi

sed 's/→/->/g' "$FILE" | awk '
function trim(s){ sub(/^[ \t]+/,"",s); sub(/[ \t]+$/,"",s); return s }
function err(m){ errs[++nerr]=m }
function warn(m){ warns[++nwarn]=m }
# split a "| a | b |" row into cells[1..]; returns count
function parse_row(line, cells,   n,i,arr,nc){
  n=split(line, arr, "|"); nc=0
  for(i=2;i<n;i++){ cells[++nc]=trim(arr[i]) }
  return nc
}
# load the first table data rows of a section into drows[1..]; returns count
function load_table(s, drows,   i,m,copy,start){
  m=0
  if(rowcount[s]<1) return 0
  start=2
  if(rowcount[s]>=2){
    copy=rows[s,2]; gsub(/[ \t|:-]/,"",copy)
    if(copy=="") start=3; else start=2
  }
  for(i=start;i<=rowcount[s];i++){ drows[++m]=rows[s,i] }
  return m
}
BEGIN{
  dn[1]="Funny ↔ Serious";              lp[1]="funny";        rp[1]="serious"
  dn[2]="Formal ↔ Casual";              lp[2]="formal";       rp[2]="casual"
  dn[3]="Respectful ↔ Irreverent";      lp[3]="respectful";   rp[3]="irreverent"
  dn[4]="Enthusiastic ↔ Matter-of-fact";lp[4]="enthusiastic"; rp[4]="matter-of-fact"
  for(k=1;k<=4;k++) isdim[dn[k]]=1
  slab[1]="Error message"; slab[2]="Marketing line"
  slab[3]="Support reply"; slab[4]="Onboarding email opener"
  nerr=0; nwarn=0; sec=""
}
{
  line=$0
  if(line ~ /^#[ \t]+Brand Voice Guide:/) has_h1=1
  # unfilled template placeholders [..], skipping markdown links "]("
  tmp=line
  while(match(tmp, /\[[^]]+\]/)){
    ph=substr(tmp,RSTART,RLENGTH)
    after=substr(tmp,RSTART+RLENGTH,1)
    if(after!="(") err("Line " NR ": unfilled template placeholder " ph)
    tmp=substr(tmp,RSTART+RLENGTH)
  }
  # section heading (## but not ###)
  if(line ~ /^##[ \t]/ && line !~ /^###/){
    sec=trim(substr(line,3)); secseen[sec]=1
    if(sec ~ /^The Voice/) voiceseen=1
    next
  }
  # capture first table per section
  if(sec!="" && line ~ /^[ \t]*\|/ && tabledone[sec]==0){
    rowcount[sec]++; rows[sec,rowcount[sec]]=line
  } else if(sec!="" && line ~ /^[ \t]*$/ && rowcount[sec]>0 && tabledone[sec]==0){
    tabledone[sec]=1
  }
  if(sec=="Sample Copy") sb[++nsb]=line
}
END{
  if(!has_h1) err("Missing H1 heading \"# Brand Voice Guide: <name>\".")
  if(!voiceseen) err("Missing required section \"## The Voice: <label>\".")
  split("Tone of Voice Dimensions|Brand Voice Chart|Sample Copy", req, "|")
  for(i=1;i<=3;i++) if(!(req[i] in secseen)) err("Missing required section \"## " req[i] "\".")

  # --- Dimensions ---
  ndr=load_table("Tone of Voice Dimensions", dimrows)
  for(i=1;i<=ndr;i++){ nc=parse_row(dimrows[i],c); if(nc>=1){ nm=c[1]; ds[nm]=(nc>=2?c[2]:""); dp[nm]=(nc>=3?c[3]:""); dr[nm]=(nc>=4?c[4]:""); dfound[nm]=1 } }
  for(k=1;k<=4;k++){
    nm=dn[k]
    if(!dfound[nm]){ err("Dimensions table is missing the row \"" nm "\"."); continue }
    s=ds[nm]
    if(s !~ /^[1-5]$/){ err("\"" nm "\": Score must be an integer 1-5, got \"" s "\"."); continue }
    sv=s+0; def[nm]=sv; pos=tolower(dp[nm])
    if(dp[nm]==""){ err("\"" nm "\": Position cell is empty.") }
    else if(sv<=2 && index(pos,lp[k])==0) err("\"" nm "\": Score " sv " (toward \"" lp[k] "\") but Position \"" dp[nm] "\" doesn'\''t name that pole.")
    else if(sv==3 && index(pos,"balanced")==0) err("\"" nm "\": Score 3 should be described \"balanced\"; Position is \"" dp[nm] "\".")
    else if(sv>=4 && index(pos,rp[k])==0) err("\"" nm "\": Score " sv " (toward \"" rp[k] "\") but Position \"" dp[nm] "\" doesn'\''t name that pole.")
    if(dr[nm]=="") err("\"" nm "\": Rationale cell is empty.")
  }

  # --- Brand Voice Chart ---
  ncr=load_table("Brand Voice Chart", chartrows)
  if(ncr<3 || ncr>5) err("Brand Voice Chart must have 3-5 trait rows, found " ncr ".")
  split("Trait|Description|Do'\''s|Don'\''ts", clab, "|")
  for(i=1;i<=ncr;i++){
    nc=parse_row(chartrows[i],c)
    if(nc<4){ err("Brand Voice Chart row has fewer than 4 columns: " chartrows[i]); continue }
    tr=(c[1]==""?"(unnamed)":c[1])
    for(j=1;j<=4;j++) if(c[j]=="") err("Brand Voice Chart row \"" tr "\": empty " clab[j] " cell.")
  }

  # --- Tone Shifts (optional) ---
  if("Tone Shifts by Context" in secseen){
    nts=load_table("Tone Shifts by Context", tsrows)
    if(nts==0) warn("Tone Shifts by Context section present but has no rows; omit it or fill it.")
    for(i=1;i<=nts;i++){
      nc=parse_row(tsrows[i],c); if(nc<2){ err("Tone shift row malformed: " tsrows[i]); continue }
      ctx=c[1]; shift=c[2]
      if(tolower(shift) ~ /^no score change/) continue
      if(shift ~ /^.+:[ \t]*[0-9]+[ \t]*->[ \t]*[0-9]+/){
        colon=index(shift,":"); dim=trim(substr(shift,1,colon-1)); rest=substr(shift,colon+1)
        ap=index(rest,"->"); fromnum=trim(substr(rest,1,ap-1))+0
        tail=substr(rest,ap+2); match(tail,/[0-9]+/); tonum=substr(tail,RSTART,RLENGTH)+0
        if(!(dim in isdim)) err("Tone shift for \"" ctx "\" names unknown dimension \"" dim "\".")
        else if((dim in def) && fromnum!=def[dim]) err("Tone shift for \"" ctx "\": \"" dim "\" default is " def[dim] " but shift starts from " fromnum ".")
        if(tonum<1 || tonum>5) err("Tone shift for \"" ctx "\": shifted score " tonum " out of range 1-5.")
      } else err("Tone shift for \"" ctx "\" must be \"Dimension: default -> shifted\" or \"No score change\"; got \"" shift "\".")
    }
  }

  # --- Sample Copy ---
  pending=0
  for(i=1;i<=nsb;i++){
    l=sb[i]
    for(k=1;k<=4;k++) if(l ~ ("\\*\\*" slab[k] ":?\\*\\*")){ present[k]=1; pending=k }
    if(l ~ /^[ \t]*>/ && pending>0) sat[pending]=1
  }
  for(k=1;k<=4;k++){
    if(!present[k]) err("Sample Copy is missing the \"" slab[k] "\" sample.")
    else if(!sat[k]) err("Sample \"" slab[k] "\" has no blockquote (>) with the actual copy.")
  }

  for(i=1;i<=nwarn;i++) print "  [warn] " warns[i]
  for(i=1;i<=nerr;i++)  print "  [ERROR] " errs[i]
  if(nerr>0){ print "\nFAIL: " nerr " error(s), " nwarn " warning(s)."; exit 1 }
  print "\nCLEAN: 0 errors, " nwarn " warning(s)."
  exit 0
}
'
