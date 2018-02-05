use v6;

use PDF::Function;

#| /FunctionType 0 - Sampled
#| see [PDF 1.7 Section 3.9.1 Type 0 (Sampled) Functions]
class PDF::Function::Sampled
    is PDF::Function {

    use PDF::DAO::Tie;
    # see [PDF 1.7 TABLE 3.36 Additional entries specific to a type 0 function dictionary]

    has UInt @.Size is entry(:required);  #| (Required) An array of m positive integers specifying the number of samples in each input dimension of the sample table.

    subset Sample of Int where 1|2|4|8|16|24|32;
    has Sample $.BitsPerSample is entry(:required); #| (Required) The number of bits used to represent each sample. (If the function has multiple output values, each one occupies BitsPerSample bits.) Valid values are 1, 2, 4, 8, 12, 16, 24, and 32.

    subset OrderInt of Int where 1|3;
    has OrderInt $.Order is entry;        #| (Optional) The order of interpolation between samples. Valid values are 1 and 3, specifying linear and cubic spline interpolation, respectively.

    has Numeric @.Encode is entry;        #| (Optional) An array of 2 × m numbers specifying the linear mapping of input values into the domain of the function’s sample table. Default value: [ 0 (Size0 − 1) 0 (Size1 − 1) … ].

    has Numeric @.Decode is entry;        #| (Optional) An array of 2 × n numbers specifying the linear mapping of sample values into the range appropriate for the function’s output values. Default value: same as the value of Range.

    # (Optional) Other attributes of the stream that provides the sample values, as appropriate

    use PDF::IO::Util :pack;
    class Interpreter
        is PDF::Function::Interpreter {
        has UInt $.bpc is required;
        has UInt @.size is required;
        has Range @.encode = @!size.map: { 0..$_ };
        has Range @.decode = self.range;
        has Blob $.samples is required;
        has UInt $!m;
        has UInt $!n;

        submethod TWEAK {
            $!m = self.domain.elems;
            $!n = self.range.elems;
            die "size/domain lengths differ" unless +@!size == $!m;
            die "encode/domain lengths differ" unless +@!encode == $!m;
            die "decode/range lengths differ" unless +@!decode == $!n;
        }

        method !input-mul($_) {
            (@!encode[$_].max - @!encode[$_].min)
                / (self.domain[$_].max - self.domain[$_].min);
        }

        method !sample(\x, \y) {
            # stub
            my \r = $!n * $!m;
            my \s0 = x + y;
            my \s1 = x + y + r;
            $!samples[s0] .. $!samples[s1];
        }

        method !interpolate($in, \x, \y) {
            my \X = @.domain[x];
            my \Y = @.range[y];
            my \R = 2 ** $!bpc - 1;
            my \S = self!sample(x, y);
            my \y0 = S.min / R;
            my \dy = (S.max - S.min) / R;
            y0 + dy * (Y.min + ($in - X.min) * (Y.max - Y.min) / (X.max - X.min))
        }

        method calc(List $in) {
            my Numeric @in = ($in.list Z @.domain).map: { self.clip(.[0], .[1]) };
            my @out;

            for 0 ..^ $!m -> \x {
               for 0 ..^ $!n -> \y {
                   @out.push: self!interpolate(@in[x], x, y);
               }
            }
            # map input values into sample array
            [(@out Z @.range).map: { self.clip(.[0], .[1]) }];
        }
    }
    method interpreter {
        my Range @domain = @.Domain.map: -> $a, $b { Range.new($a, $b) };
        my Range @range = @.Range.map: -> $a, $b { Range.new($a, $b) };
        my @size = @.Size;
        my Range @encode = do with $.Encode {
            .keys.map: -> $k { 0 .. .[$k] }
        }
        else {
            @size.map: { 0 .. ($_-1) };
        }
        my Range @decode = do with $.Decode {
            .keys.map: -> $k { 0 .. .[$k] }
        }
        else {
            @range;
        }
        my $bpc = $.BitsPerSample;
        my Blob $samples = unpack($.decoded, $bpc);

        Interpreter.new: :@domain, :@range, :@size, :@encode, :@decode, :$samples, :$bpc;
    }
    #| run the calculator function
    method calc(List $in) {
        $.interpreter.calc($in);
    }
}
