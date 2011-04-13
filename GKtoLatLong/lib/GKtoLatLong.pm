package GKtoLatLong;

#Default Perl module
use 5.006001;
use strict;
use warnings;

#custom for this module
use POSIX qw'atan atan2 floor tan'; #POSIX for mathematical functions
use constant PI => 4 * atan2(1, 1); #Definition of Pi

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use GKtoLatLong ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
convGKtoLatLong
convertGaussKruegerToLatitudeLongitude
sevenParameterHelmertTransformation
convertToClassicNotation
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
convGKtoLatLong
convertGaussKruegerToLatitudeLongitude
sevenParameterHelmertTransformation
convertToClassicNotation
);

our $VERSION = '0.01';

# Preloaded methods go here.

#Simple conversion. Will do for most users.
sub convGKtoLatLong
{
  use Carp; #For giving the caller an idea what went wrong

  if((!defined($_[0])) || (!defined($_[1])))
  {
	  carp "Missing parameters. We need at least two parameters - first for right and second for height.\n";
  }

  &convertGaussKruegerToLatitudeLongitude( $_[0], $_[1] );

  if(defined($_[2]))
  {
    &sevenParameterHelmertTransformation( $_[0], $_[1] , $_[2] );
  } else {
    &sevenParameterHelmertTransformation( $_[0], $_[1] );
  }
}

sub convertGaussKruegerToLatitudeLongitude
{
	use Carp; #For giving the caller an idea what went wrong

	my @out=@_;

	if((!defined($out[0])) || (!defined($out[1])))
	{
		carp "Missing parameters. We need at least two parameters - first for right and second for height.\n";
	}
	
	#Check for invalid Parameters
	if (!(($out[0] > 1000000) && ($out[1] > 1000000)))
	{
		carp "No valid Gauss-Kruger-Code!\n";
	}
	
	#Variables to prepare the geovalues
	my $GKRight = $out[0];
	my $GKHeight = $out[1];
	my $e2 = 0.0067192188;
	my $c = 6398786.849;
	my $rho = 180 / PI;
	my $bII = ($GKHeight / 10000855.7646) * ($GKHeight / 10000855.7646);
	my $bf = 325632.08677 * ($GKHeight / 10000855.7646) * ((((((0.00000562025 * $bII + 0.00022976983) * $bII - 0.00113566119) * $bII + 0.00424914906) * $bII - 0.00831729565) * $bII + 1));
	my $GeoDezRight;
	my $GeoDezHeight;
	my $dl;
	my $co;
	my $g2;
	my $g1;
	my $t;
	my $fa;
	
	$bf /= 3600 * $rho;
	$co = cos($bf);
	$g2 = $e2 * ($co * $co);
	$g1 = $c / sqrt(1 + $g2);
	$t = tan($bf); 
	$fa = ($GKRight - floor($GKRight / 1000000) * 1000000 - 500000) / $g1;
	 
	$GeoDezRight = (($bf - $fa * $fa * $t * (1 + $g2) / 2 + $fa * $fa * $fa * $fa * $t * (5 + 3 * $t * $t + 6 * $g2 - 6 * $g2 * $t * $t) / 24) * $rho);
	$dl = $fa - $fa * $fa * $fa * (1 + 2 * $t * $t + $g2) / 6 + $fa * $fa * $fa * $fa * $fa * (1 + 28 * $t * $t + 24 * $t * $t * $t * $t) / 120;
	$GeoDezHeight = $dl * $rho / $co + floor($GKRight / 1000000) * 3;
	
	#change our parameters
	$_[0] = $GeoDezRight;
	$_[1] = $GeoDezHeight;
}

sub sevenParameterHelmertTransformation
{
	use Carp; #For giving the caller an idea what went wrong
	
	my @out=@_;
	my $WGS84 = 1; #Uses GRS80 if 0
	
	if((!defined($out[0])) || (!defined($out[1])))
	{
		carp "Missing parameters. We need at least two parameters - first for right and second for height.\n";
	}
		
	#If one wants to specify the used system, he can pass us a third paramter.
	if (defined($out[2]))
	{
  		$WGS84 = $out[2];
  	}
	
	#Parameters seem to look good until here, we start with the transformation
	
	#Variables used in the transformation
	my $earthRadius = 6378137; #Earth is a sphere witht this radius
	my $aBessel = 6377397.155;
	my $eeBessel = 0.0066743722296294277832;
	my $ScaleFactor = 0.00000982;
	my $RotXRad = -7.16069806998785E-06;
	my $RotYRad = 3.56822869296619E-07;
	my $RotZRad = 7.06858347057704E-06;
	my $ShiftXMeters = 591.28;
	my $ShiftYMeters = 81.35;
	my $ShiftZMeters = 396.39;
	my $LatitudeIt = 99999999;
	my $Latitude;
	my $n;
	my $CartOutputXMeters;
	my $CartOutputYMeters;
	my $CartOutputZMeters;
	my $CartesianXMeters;
	my $CartesianYMeters; 
	my $CartesianZMeters;
	my $ee;
	my $GeoDezRight = $out[0];
	my $GeoDezHeight = $out[1];
	
	if($WGS84)
	{
		$ee = 0.0066943799;
	} else {
		$ee = 0.00669438002290;
	}
	
	$GeoDezRight = ($GeoDezRight / 180) * PI;
	$GeoDezHeight = ($GeoDezHeight / 180) * PI;
	
	$n = $eeBessel * sin($GeoDezRight) * sin($GeoDezRight);
	$n = 1 - $n;
	$n = sqrt($n);
	$n = $aBessel / $n;
	
	$CartesianXMeters = $n * cos($GeoDezRight) * cos($GeoDezHeight);
	$CartesianYMeters = $n * cos($GeoDezRight) * sin($GeoDezHeight);
	$CartesianZMeters = $n * (1 - $eeBessel) * sin($GeoDezRight);
	
	$CartOutputXMeters = (1 + $ScaleFactor) * $CartesianXMeters + $RotZRad * $CartesianYMeters - $RotYRad * $CartesianZMeters + $ShiftXMeters;
	$CartOutputYMeters = -$RotZRad * $CartesianXMeters + (1 + $ScaleFactor) * $CartesianYMeters + $RotXRad * $CartesianZMeters + $ShiftYMeters;
	$CartOutputZMeters = $RotYRad * $CartesianXMeters - $RotXRad * $CartesianYMeters + (1 + $ScaleFactor) * $CartesianZMeters + $ShiftZMeters;
	
	$GeoDezHeight = atan($CartOutputYMeters / $CartOutputXMeters);
	
	$Latitude = ($CartOutputXMeters * $CartOutputXMeters) + ($CartOutputYMeters * $CartOutputYMeters);
	$Latitude = sqrt($Latitude);
	$Latitude = $CartOutputZMeters / $Latitude;
	$Latitude = atan($Latitude);
	
	do
	{
		$LatitudeIt = $Latitude;
	
	  $n = 1 - $ee * sin($Latitude) * sin($Latitude);
	  $n = sqrt($n);
	  $n = $earthRadius / $n;
	
	  $Latitude = $CartOutputXMeters * $CartOutputXMeters + $CartOutputYMeters * $CartOutputYMeters;
	  $Latitude = sqrt($Latitude);
	  $Latitude = ($CartOutputZMeters + $ee * $n * sin($LatitudeIt)) / $Latitude;
	  $Latitude = atan($Latitude);
	}
	while (abs($Latitude - $LatitudeIt) >= 0.000000000000001);
		
	$GeoDezRight = ($Latitude / PI) * 180;
	$GeoDezHeight = ($GeoDezHeight) / PI * 180;

	#Alter the parameters
	$_[0] = $GeoDezRight;
	$_[1] = $GeoDezHeight;
}

#Convert the Value into classic notation
sub convertToClassicNotation
{
  my $param = pop(@_);
  my $SecondsAbs = ($param - floor($param - floor(($param - floor($param)) * 60) / 60) * 60 * 60);
  my $ShortedSecondsRest = $SecondsAbs - floor($SecondsAbs);
  $SecondsAbs = floor($SecondsAbs);
  $ShortedSecondsRest = floor($ShortedSecondsRest * 100); # -> Zwei Stellen

  #Building of the Output-String
  return(floor($param) . '°' . floor(($param - floor($param)) * 60) . "\'" . $SecondsAbs . '.' . $ShortedSecondsRest . '"');
}



1;
__END__
=head1 GKtoLatLong

Perl extension to convert a point in a Gauss-Krüger coordinate system into a latitude / longitude value.

=head1 USAGE

  use GKtoLatLong;
  
  my $GKRight = 3477733; #Right
  my $GKHeight = 5553274; #Height

  #Into what format converts this script?
  my $WGS84 = 1; #Uses GRS80 if 0

  #the easy way:
  convGKtoLatLong( $GKRight , $GKHeight , $WGS84 );

  print "Lat: $GKRight\nLong: $GKHeight\n";

  #resetting values
  $GKRight = 3477733; #Right
  $GKHeight = 5553274; #Height

  #You don't need to specify $WGS84
  convGKtoLatLong( $GKRight , $GKHeight );

  #and you can modify the output to be displayed in classic notation
  print "Lat: ". &convertToClassicNotation($GKRight) . "\nLong: " . &convertToClassicNotation($GKHeight) . "\n";

  #If you know what happens with these formulas, you may find these two useful:
  #&convertGaussKruegerToLatitudeLongitude( $right, $height );
  #&sevenParameterHelmertTransformation( $right, $height , $wgs84 );
  #
  #&convGKtoLatLong is based on these.

=head1 DESCRIPTION

This is the source of a Perl module to convert a point in a Gauss-Krüger coordinate system into a latitude / longitude value.


=head2 EXPORT

All subs.


=head1 SEE ALSO

Florian Wetzels JavaScript converter that was used as source for the code:
http://calc.gknavigation.de/

=head1 AUTHOR

Niko Wenselowski <lt>der@nik0.de<gt>

=head1 COPYRIGHT AND LICENSE

Copyright is for losers.

This software is delivered 'as is'. I do not take any responsibility for the actions this module may cause. 
You may feel free to alter, share and use it in any way you like it.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
=cut
