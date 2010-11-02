function smi_add_path(op)
%ADD_MLEARNLAB Adds paths of mlearnlab into MATLAB system
%
%   add_smitoolbox_path;
%       It adds the path of all relevant directories of smitoolbox to
%       MATLAB search paths (for current MATLAB sesssion). 
%
%   add_smitoolbox_path save;
%       It saves the paths and save them.
%   

%   History
%   -------
%       - Created by Dahua Lin, on Oct 4, 2008
%       - Modified by Dahua Lin, on Apr 7, 2010
%           - switch to the new toolbox: smitoolbox
%           - add the option 'save'
%

%% verify input arguments

if nargin >= 1
    assert(ischar(op) && strcmpi(op, 'save'), ...
        'add_smitoolbox_path:invalidarg', ...
        'the only argument that can be input to this function is ''save''.');
    
    to_save_path = true;
else
    to_save_path = false;
end

%% main

rootdir = fileparts(fileparts(mfilename('fullpath')));

subdirs = { ...
    'base/calc', ...
    'base/clib', ...
    'base/matrix', ...
    'base/metrics', ...
    'base/sample', ...
    'classics/cluster', ...
    'classics/subspace', ...
    'graph/common', ...
    'graph/mincut', ...
    'graph/manifold', ...
    'graph/grid', ...    
    'optim', ...
    'pmodels/common', ...
    'pmodels/ddistr', ...
    'pmodels/gauss', ...
    'tbman'
};

subpaths = cellfun(@(x) fullfile(rootdir, x), subdirs, 'UniformOutput', false);
addpath(subpaths{:});
    
if to_save_path
    savepath;
end


