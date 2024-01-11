function compare_structs(struct1, struct2, compare_values)
% Compares the fields of two structs. Displays a message if one field is
% not found in the other struct, and vice versa. If a field is a struct
% itself, the comparison is applied recursively.
%
% When compare_values is false, check for the existence of fields only.
% When compare_values is true, compare the values of the fields as well.
%
% Nathan Blanken, University of Twente, 2023

fprintf('Comparing the first struct against the second struct:\n')
difference_found = matchfields(struct1,struct2, compare_values);
if ~difference_found
    disp('All fields match.')
end
fprintf('\n')

fprintf('Comparing the second struct against the first struct:\n')
difference_found = matchfields(struct2, struct1, compare_values);
if ~difference_found
    disp('All fields match.')
end
fprintf('\n')

end

function difference_found = matchfields(struct1,struct2, ...
    compare_values, varargin)

% Set superstruct string and difference found boolean, if not given:
switch nargin
    case {0,1,2,4}
        error('Not enough input arguments.')
    case 3
        superstruct_str = [];
        difference_found = false;
    case 5 
        superstruct_str = varargin{1};
        difference_found = varargin{2};
    otherwise
        error('Too many input arguments.')
end

% Loop through all field names:
fieldNames = fieldnames(struct1);

for n = 1:length(fieldNames)
    if isfield(struct2,fieldNames{n})
        
        field1 = struct1.(fieldNames{n});
        field2 = struct2.(fieldNames{n});
        
        if isstruct(field1)
            % If field is a struct itself, apply the search recursively:
            substruct_str = [superstruct_str, fieldNames{n} '.'];
            
            difference_found = matchfields(field1, field2, ...
                compare_values, substruct_str, difference_found);
            
        elseif compare_values && ~strcmp(class(field1),class(field2))
            disp(['Class mismatch: ' superstruct_str fieldNames{n}])
            difference_found = true;
            
        elseif compare_values && ~isequal(field1,field2)
            disp(['Value mismatch: ' superstruct_str fieldNames{n}])
            difference_found = true;
        end
        
    else
        % If no match found, display the field name:
        disp(['Missing field:  ' superstruct_str fieldNames{n}])
        difference_found = true;
    end
end

end