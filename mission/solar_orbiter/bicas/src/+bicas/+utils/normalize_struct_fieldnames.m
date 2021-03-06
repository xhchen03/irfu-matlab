%
% "Normalize" the fieldnames of a struct, i.e. assume that fieldnames can have multiple pre-defined variations (each
% actually used fieldname is one in a set) and convert these to the canonical fieldnames.
%
%
% ARGUMENTS
% =========
% S        : Arbitrary struct
% normList : "Normalization list"
%            {i}{1} = Cell array of fieldnames which, when found in S, are renamed to {i}{2} (a string).
%            IMPLEMENTATION NOTE: Structure of normList is chosen to be suitable for hardcoding.
%            NOTE: The sets {i}{1} must not overlap.
% --
% Can also be used for always changing fieldname, since normList{i}{2} does not have to be a member of normList{i}{1}.
%
%
% Author: Erik P G Johansson, Uppsala, Sweden
% First created 2019-12-02
%
function S = normalize_struct_fieldnames(S, normList)
    % TODO-DECISION: How handle fieldnames which are not found?
    %   PROPOSAL: Better to "translate" (change concept) when fieldnames are found, and ignore otherwise.
    %       PRO/NOTE: Can already "translate" fieldnames (change names arbitrarily) since normList{i}{2} does not have to be a member of normList{i}{1}.
    %   PROPOSAL: Policy argument.
    % PROPOSAL: Test code.
    %
    % PROPOSAL: Return ~flags for what has been changed.
    %   PRO: Caller can print warnings based on it.

    fnList = fieldnames(S);

    % NL = Normalization List
    for iNl = 1:numel(normList)    % Iterate over items in NORMALIZATION LIST (not over fieldnames in S).
        % ASSERTION: Check argument format.
        assert(numel(normList{iNl}) == 2, 'Not exactly two elements in normList{%i}.', iNl)
                
        fnAlternatives = normList{iNl}{1};
        newFn          = normList{iNl}{2};
        
        assert(~isempty(fnAlternatives), 'normList{%i}{1} is empty.', iNl)
        
        iFn = find(ismember(fnList, fnAlternatives));   % Indices into fnList: Fieldnames which match normalized field name iNl (should be exactly one).
        % ASSERTION: There is exactly one fieldname that matches the current canonical fieldname (item in normList).
        assert(isscalar(iFn), 'Did not find exactly one field name that matches any of normList{%i}{1}={"%s"}.', iNl, strjoin(fnAlternatives, '", "'))

        

        oldFn = fnList{iFn};
        EJ_library.utils.assert.castring(newFn)
        
        if ~strcmp(oldFn, newFn)
            S.(newFn) = S.(oldFn);
            S         = rmfield(S, oldFn);
        end
    end
end
