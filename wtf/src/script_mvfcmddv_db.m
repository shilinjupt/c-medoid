%% PROJETO AM 2016-1
% =========================================================================
% Exercise (1)
% Considere os dados "multiple features" do site uci machine learning 
% repository (http://archive.ics.uci.edu/ml/).
%
% a) Compute 3 matrizes de dissimilaridade (um para cada tabela de dados
%    mfeat-fac, mfeat-fou, mfeat-kar) usando a distancia Euclidiana.
% b) Execute o algoritmo "Multi-view relacional fuzzy c-medoids vectors
%    clustering algorithm - MVFCMddV" simultaneamente nessas 6 matrizes de
%    dissimilaridade 100 vezes para obter uma parti��o fuzzy em 10 grupos e
%    selecione o melhor resultado segundo a fun��o objetivo. Para detalhes 
%    do algoritmo "Multi-view relacional fuzzy c-medoids vectors clustering
%    algorithm - MVFCMddV" veja a se��o 2 do artigo:
%    [1] de Carvalho, F. D. A., de Melo, F. M., & Lechevallier, Y. (2015). 
%    A multi-view relational fuzzy c-medoid vectors clustering algorithm. 
%    Neurocomputing, 163, 115-123.
%
% -------------------------------------------------------------------------
% Observa��es:
% -------------------------------------------------------------------------
% - Parametros: K = 10; m = 1.6; T = 150; eps = 1e-10
% - Para o melhor resultado imprimir: i) a parti��o fuzzy (matrix U), ii) a 
%   matriz de pesos iii) a parti��o hard (para cada grupo, a lista de 
%   objetos), vi) para cada grupo a lista de medoids, v) 0 �ndice de Rand 
%   corrigido.
%

%% Initialization
clear ; close all; clc
run('addPathToKernel');

% global dir
path_in_db = '../db/';
path_out = '../out/';

fprintf('Projeto AM 2016-1 ... \n');
fprintf('Running sintectic samples ... \n');

%% Load data
fprintf('Reading data file ... \n');

rng(1);

% signal load file
% 1. mfeat-fou: 76 Fourier coefficients of the character shapes; 
% 2. mfeat-fac: 216 profile correlations;  ***
% 3. mfeat-kar: 64 Karhunen-Lo�ve coefficients; *** 
% 4. mfeat-pix: 240 pixel averages in 2 x 3 windows; (15x16)
% 5. mfeat-zer: 47 Zernike moments; 
% 6. mfeat-mor: 6 morphological features. ***

n = 2000;
X1 = load([path_in_db 'mfeatfou.mat'],'X'); X1 = X1.X(1:n,:);
X2 = load([path_in_db 'mfeatzer.mat'],'X'); X2 = X2.X(1:n,:);
X3 = load([path_in_db 'mfeatkar.mat'],'X'); X3 = X3.X(1:n,:);


% normalize vector

X1 = featureNormalize(X1);
X2 = featureNormalize(X2);
X3 = featureNormalize(X3);

n = size(X1,1);
p = 3;

%% Calculate  Dissimilarity Matrix
fprintf('Calculate  Dissimilarity Matrix ... \n');

D = zeros(n,n,3);

% Local code
% D(:,:,1) = dissimilarityMatrix( X1 );
% D(:,:,2) = dissimilarityMatrix( X2 );
% D(:,:,3) = dissimilarityMatrix( X3 );

% Matlab code
D(:,:,1) = pdist2(X1,X1);
D(:,:,2) = pdist2(X2,X2);
D(:,:,3) = pdist2(X3,X3);

% normalize matrix 
% D = dissimilarityNormalize( D );



%% Fuzzy c-medoids vectors clustering algorithm
fprintf('Fuzzy c-medoids vectors clustering algorithm ... \n\n');

% configurate

K = 10;     % k clusters
m = 1.6;    % parameter (1<m<oo)
T = 150;    % iteration limit
e = 1e-10;  % epsilom error

N = 100;
Jt = zeros(N,1); 
Gt = zeros(K,p,N); 
Lambdat = zeros(K,p,N); 
Ut = zeros(n,K,N);
cellJ = cell(N,1);

% execute

for i=1:N

    % execute methods
    [ G, Lambda, U, J, Js ] = MVFCMddV( D, K, m, T, e );
    
    cellJ{i} = Js;
    Jt(i) = J;
    Gt(:,:,i) = G;
    Lambdat(:,:,i) = Lambda;
    Ut(:,:,i) = U;

    fprintf('Iter %d/%d, Cost J: %d \n', i, N, J);
    fprintf('---\n');
    
end

% select de best result

[J, Imin] = min(Jt);
G = Gt(:,:,Imin);
Lambda = Lambdat(:,:,Imin);
U = Ut(:,:,Imin);

% ajusted rand index calculate

Q  = hardClusters(U);
W  = repmat(1:K,200,1); W = W(:); % class prior
W  = expandcol(W,K); 
ARI = ajustedRandIndex(Q,W); %1043
[ ~,~,~,~, F1 ] = measuresEvaluate(Q, W);

% save('ws1-1');


%% Save result
fprintf('\nSave result ...\n');
fprintf('Min error J(x)=%d for iter %d\n', J, Imin);
 
% (i)   the fuzzy partition (matrix U)
% (ii)  the matrix weight (matix Lamnda)
% (iii) the hard partition (matix Q)
% (iv)  the list of medoids for groups (matrix G)
% (v)   rand index ajusted (RIA)

% csvwrite

csvwrite([path_out 'matU.dat'], U);
csvwrite([path_out 'matLambda.dat'], Lambda);
csvwrite([path_out 'matQ.dat'], Q);
csvwrite([path_out 'matG.dat'], G);

% print result
fprintf('Result. Is showing the 5 first results ...\n')
fprintf('i)   Parti��o fuzzy (show 5x5): \n'); 
disp(U(1:5,1:5))
fprintf('ii)  Matriz de pesos (show 5x3): \n'); 
disp(Lambda(1:5,1:3))
fprintf('iii) Parti��o hard (show 5x5): \n'); 
disp(Q(1:5,1:5))
fprintf('iv) Lista de medoides (show 5x3): \n'); 
disp(G(1:5,1:3))

fprintf('v)  ARI: %.3d \n', ARI);
fprintf('vi) F1: %.3d \n', F1);


%% Show result

% %  % show cost J
% %  figure(3); plot(Jt); hold on
% %  plot(Imin,J,'or');
% %   title('Cost Function J(x) for 100 iteration');
% %  xlabel('Iterartion');
% %  ylabel('Error');

color = hsv(N);
figure; hold on
for i=1:N
    Ji = cellJ{i};
    plot(Ji,'-o','LineWidth', 1.75, 'col', color(i,:));
end
hold off
xlabel('Iterartion');
ylabel('J(G,\Lambda,U)');
title([mat2str(N) ' costs functions' ]);

box('on');



