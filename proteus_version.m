function [version, parts] = proteus_version()
%PROTEUS_VERSION Version of PROTEUS.
%
% version = PROTEUS_VERSION() returns the version as a character vector,
% for example '1.1.0'.
%
% [version, parts] = PROTEUS_VERSION() also returns [major minor patch] as
% a numeric row vector, to compare versions, for example:
%
%   [~, v] = proteus_version();
%   if v(1) < 1 || (v(1) == 1 && v(2) < 1)
%       error('PROTEUS 1.1 or later is required.')
%   end
%
% The version follows semantic versioning: the major number changes for
% incompatible changes, the minor number for new features, the patch
% number for fixes. It must match the version in CITATION.cff and the git
% tag of the release (v<version>).

version = '1.1.0';
parts   = sscanf(version, '%d.%d.%d')';

end
