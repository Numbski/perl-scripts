use Foundation;

sub perlValue {
  my ( $object ) = @_;
  return "" if ref($object) eq 'SCALAR';
  return $object->description()->UTF8String();
}

# more subroutines go here...

1;

