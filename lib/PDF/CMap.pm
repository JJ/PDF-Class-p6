use v6;

use PDF::DAO::Dict;
use PDF::DAO::Stream;
use PDF::Doc::Type;

# /Type /CMap

class PDF::CMap
    is PDF::DAO::Stream
    does PDF::Doc::Type {

    # set [PDF 1.7 TABLE 5.17 Additional entries in a CMap dictionary]
    use PDF::DAO::Tie;
    use PDF::DAO::Name;
    my subset Name-CMap of PDF::DAO::Name where 'CMap';
    has Name-CMap $.Type is entry(:required);
    has PDF::DAO::Name $.CMapName is entry(:required); #| (Required) The PostScript name of the CMap. It should be the same as the value of CMapName in the CMap file.
    has Hash $.CIDSystemInfo is entry(:required);         #| (Required) A dictionary containing entries that define the character collection for the CIDFont or CIDFonts associated with the CMap
    my subset ZeroOrOne of UInt where 0|1;
    has ZeroOrOne $.WMode is entry;                       #| (Optional) A code that determines the writing mode for any CIDFont with which this CMap is combined. The possible values are 0 for horizontal and 1 for vertical
    my subset NameOrStream where PDF::DAO::Name | PDF::DAO::Stream;
    has NameOrStream $.UseCMap is entry;                  #| (Optional) The name of a predefined CMap, or a stream containing a CMap, that is to be used as the base for this CMap
}