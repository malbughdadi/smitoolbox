// a special file for syntax checking of template libraries


#include "matlab_types.h"
#include "marray.h"

#include "array.h"

using namespace smi;

template class Array<double>;
template class Array<bool>;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
}