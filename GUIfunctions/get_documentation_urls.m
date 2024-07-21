function Documentation = get_documentation_urls()
%GET_DOCUMENTATION_URLS returns a struct with URLs to the online
%documentation. The links are accessed by the help buttons.
%
% Nathan Blanken, University of Twente, 2023

githubURL = 'https://github.com/PROTEUS-SIM/';
repoURL   = [githubURL 'PROTEUS/blob/main/'];
docURL    = [repoURL 'documentation/'];

Documentation.Main = [repoURL 'README.md'];

Documentation.Acquisition          = [docURL 'AcquisitionGUI.md'];
Documentation.Geometry             = [docURL 'GeometryGUI.md'];
Documentation.Medium               = [docURL 'MediumGUI.md'];
Documentation.Microbubbles         = [docURL 'MicrobubblesGUI.md'];
Documentation.SimulationParameters = [docURL 'SimulationParametersGUI.md'];
Documentation.Transducer           = [docURL 'TransducerGUI.md'];
Documentation.Transmit             = [docURL 'TransmitGUI.md'];

end