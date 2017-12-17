use v6;
use Test;
plan 15;

use PDF::Class;

isa-ok PDF::Class.loader.load-delegate( :dict{ :Type<Page> }), ::('PDF::Page'), 'delegation sanity';
isa-ok PDF::Class.loader.load-delegate( :dict{ :Type<XObject>, :Subtype<Image> }), ::('PDF::XObject::Image'), 'delegation to subclass';
isa-ok PDF::Class.loader.load-delegate( :dict{ :ShadingType(7) }),  ::('PDF::Shading::Tensor'), 'delegation by ShadingType';
isa-ok PDF::Class.loader.load-delegate( :dict{ :ShadingType(42) }),  ::('PDF::Shading'), 'delegation by ShadingType (unknown)';
isa-ok PDF::Class.loader.load-delegate( :dict{ :Type<Unknown> }, :fallback(Hash)), Hash, 'delegation fallback';
isa-ok PDF::Class.loader.load-delegate( :dict{ :FunctionType(3) }),  ::('PDF::Function::Stitching'), 'delegation by FunctionType';

isa-ok PDF::Class.loader.load-delegate( :dict{ :Subtype<Link> }),  ::('PDF::Annot::Link'), 'annot defaulted /Type - implemented';
isa-ok PDF::Class.loader.load-delegate( :dict{ :Subtype<Caret> }, ),  ::('PDF::Annot'), 'annot defaulted /Type - unimplemented';
isa-ok PDF::Class.loader.load-delegate( :dict{ :S<GTS_PDFX> }, ),  ::('PDF::OutputIntent'), 'output intent defaulted /Type';

require ::('PDF::Pages');
my $pages = ::('PDF::Pages').new;
is $pages.Type, 'Pages', '$.Type init';

require ::('PDF::XObject::Form');
my $form = ::('PDF::XObject::Form').new( :dict{ :BBox[0, 0, 100, 140 ] } );
is $form.Type, 'XObject', '$.Type init';
is $form.Subtype, 'Form', '$.Subtype init';

require ::('PDF::Shading::Radial');
my $shading = ::('PDF::Shading::Radial').new( :dict{ :ColorSpace(:name<DeviceRGB>),
								:Function(:ind-ref[15, 0]),
								:Coords[ 0.0, 0.0, 0.096, 0.0, 0.0, 1.0, 0],
							 } );
is $shading.ShadingType, 3, '$.ShadingType init';

require ::('PDF::Function::PostScript');
my $function;
lives-ok { $function = ::('PDF::Function::PostScript').new( :dict{ :Domain[-1, 1, -1, 1] } )}, "PostScript require";
lives-ok {$function.FunctionType}, 'FunctionType accessor';
