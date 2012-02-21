// Based on UTCOMP spinnyweap :o.
Class MNAF_PreviewWep Extends SpinnyWeap;

Function Tick( float dt )
{
	local vector X,Y,Z;
    local vector X2,Y2;
    local rotator R2;
    local vector  V;
    local rotator R;

	R = Rotation;
    R2.Yaw = dt * SpinRate/Level.TimeDilation;
    GetAxes( R, X, Y, Z );
    V = vector( R2 );
    X2 = V.X * X + V.Y * Y;
    Y2 = V.X * Y - V.Y * X;
    R2 = OrthoRotation( X2, Y2, Z );
    SetRotation( R2 );
	CurrentTime += dt/Level.TimeDilation;
}