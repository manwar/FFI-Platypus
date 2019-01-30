package FFI::Platypus::Lang::Rust;

use strict;
use warnings;

# ABSTRACT: Documentation and tools for using Platypus with the Rust programming language
# VERSION

=head1 SYNOPSIS

Rust:

 #![crate_type = "dylib"]
 
 // compile with: rustc add.rs
 
 #[no_mangle]
 pub extern "C" fn add(a:i32, b:i32) -> i32 {
   a+b
 }

Perl:

 use FFI::Platypus;
 my $ffi = FFI::Platypus->new;
 $ffi->lang('Rust');
 $ffi->lib('./libadd.so');
 
 $ffi->attach( add => ['i32', 'i32'] => 'i32' );
 
 print add(1,2), "\n";  # prints 3

=head1 DESCRIPTION

This module provides native Rust types for L<FFI::Platypus> in order to 
reduce cognitive load and concentrate on Rust and forget about C types.  
This document also documents issues and caveats that I have discovered 
in my attempts to work with Rust and FFI.

This module is somewhat experimental.  It is also available for adoption 
for anyone either sufficiently knowledgeable about Rust or eager enough 
to learn enough about Rust.  If you are interested, please send me a 
pull request or two on the project's GitHub.

Note that in addition to using pre-compiled Rust libraries, you can 
bundle Rust code with your Perl distribution using 
L<Module::Build::FFI::Rust>.

=head1 CAVEATS

In doing my testing I have been using the pre-release 1.0.0 Alpha 
version of Rust.  Rust is a very fast moving target!  I have rarely 
found examples on the internet that still work by the time I get around 
to trying them.  Fast times.  Hopefully when it becomes stable things 
will change.

=head2 name mangling

Rust names are "mangled" to handle features such as modules and the fact 
that some characters in Rust names are illegal machine code symbol 
names. For now that means that you have to tell Rust not to mangle the 
names of functions that you are going to call from Perl.  You can 
accomplish that like this:

 #[no_mangle]
 pub extern "C" fn foo() {
 }

You do not need to add this decoration to functions that you do not 
directly call from Perl.  For example:

 fn bar() {
 }
 
 #[no_mangle]
 pub extern "C" fn foo() {
   bar();
 }

In the future we may add support for name mangling so that you can use 
the Rust names, as we attempt to do for L<C++|FFI::Platypus::Lang::CPP>. 
In fact we may be able to use the same technique, as it appears that 
Rust uses the same mangling format.

=head1 METHODS

Generally you will not use this class directly, instead interacting with
the L<FFI::Platypus> instance.  However, the public methods used by
Platypus are documented here.

=head2 native_type_map

 my $hashref = FFI::Platypus::Lang::Rust->native_type_map;

This returns a hash reference containing the native aliases for the Rust 
programming languages.  That is the keys are native Rust types and the 
values are libffi native types.

=cut

sub native_type_map
{
  require FFI::Platypus;
  {
    u8       => 'uint8',
    u16      => 'uint16',
    u32      => 'uint32',
    u64      => 'uint64',
    i8       => 'sint8',
    i16      => 'sint16',
    i32      => 'sint32',
    i64      => 'sint64',
    binary32 => 'float',    # need to check this is right
    binary64 => 'double',   #  "    "  "     "    "  "
    f32      => 'float',
    f64      => 'double',
    usize    => FFI::Platypus->type_meta('size_t')->{ffi_type},
    isize    => FFI::Platypus->type_meta('ssize_t')->{ffi_type},
  },
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Platypus>

The Core Platypus documentation.

=item L<Module::Build::FFI::Rust>

Bundle Rust code with your FFI / Perl extension.

=back

=cut
