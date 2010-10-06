/********************************************************************
 *
 *  gr_neighbors_cimp.cpp
 *
 *  The C++ mex implementation of gr_neighbor.m
 *
 *  Created by Dahua Lin, on Oct 1, 2010
 *
 ********************************************************************/

#include "../../clib/mgraph.h"

using namespace smi;

template class RefWGraph<double>;
template class WAdjList<double>;

inline void raise_operr()
{
    mexErrMsgIdAndTxt("gr_neighbors:invalidarg", "The op char is invalid.");
}


mxArray* nbnodes_to_matlab_cells(const AdjList& nbh)
{
    int n = nbh.nnodes();
    mxArray *mxC = mxCreateCellMatrix(n, 1);
    for (int i = 0; i < n; ++i)
    {
        mxArray *mxI = src_to_matlab_matrix<int>(1, nbh.neighbor_num(i), nbh.neighbor_nodes(i));
        mxSetCell(mxC, i, mxI);
    }    
    return mxC;
}

template<typename T>
mxArray* nbweights_to_matlab_cells(const WAdjList<T>& nbh)
{
    int n = nbh.nnodes();
    mxArray *mxC = mxCreateCellMatrix(n, 1);
    for (int i = 0; i < n; ++i)
    {
        mxArray *mxI = src_to_matlab_matrix<T>(1, nbh.neighbor_num(i), nbh.neighbor_weights(i));
        mxSetCell(mxC, i, mxI);
    }
    return mxC;
}


mxArray* do_extract_nbs(const MArray& mG, char op)
{
    RefGraph G = to_refgraph(mG);
    
    if (op == 'o' || op == 'O')
    {
        AdjList nbh(G);
        return nbnodes_to_matlab_cells(nbh);        
    }
    else if (op == 'i' || op == 'I')
    {
        AdjList nbh(transpose(G));
        return nbnodes_to_matlab_cells(nbh);
    }
    else
    {
        raise_operr();
        return 0;
    }
}


template<typename T>
void do_extract_wnbs(const MArray& mG, char op, mxArray*& mxNbs, mxArray*& mxWs)
{
    RefWGraph<T> G = to_refwgraph<T>(mG);
    
    if (op == 'o' || op == 'O')
    {
        WAdjList<T> nbh(G);
        mxNbs = nbnodes_to_matlab_cells(nbh);     
        mxWs = nbweights_to_matlab_cells(nbh);
    }
    else if (op == 'i' || op == 'I')
    {
        WAdjList<T> nbh(transpose(G));
        mxNbs = nbnodes_to_matlab_cells(nbh);
        mxWs = nbweights_to_matlab_cells(nbh);
    }
    else
    {
        raise_operr();
    }
}
       

// main entry:
//  Input:
//    [0] G:    the mgraph struct
//    [1] op:   the option code (char)
//
//  Output:
//    [0] nbs:  the cell array of neighbor indices
//    [1] nws:  the cell array of neighbor weights (optional)
//
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    MArray mG(prhs[0]);
    MArray mOp(prhs[1]);
    
    char op = (char)(mOp.get_scalar<mxChar>());
    
    if (nlhs <= 1)
    {
        plhs[0] = do_extract_nbs(mG, op);
    }
    else
    {
        mxClassID wcid = get_graph_weight_class(mG);
        
        switch (wcid)
        {
            case mxDOUBLE_CLASS:
                do_extract_wnbs<double>(mG, op, plhs[0], plhs[1]);
                break;
            case mxINT32_CLASS:
                do_extract_wnbs<int>(mG, op, plhs[0], plhs[1]);
                break;
            case mxSINGLE_CLASS:
                do_extract_wnbs<float>(mG, op, plhs[0], plhs[1]);
                break;
        }        
    }            
    
}


