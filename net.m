% Solve an Autoregression Time-Series Problem with a NAR Neural Network
% Script generated by NTSTOOL
% Created Sat Sep 05 13:37:22 IST 2015
%
% This script assumes this variable is defined:
% ts_x - feedback time series.
%t=[0:0.1:20];
%A=1;
%f=1000;
%ts_x = A*sin(f*t);
N = 90;
t = csvread ('Generated_datasets/ts_data_x.csv');
ts_x = t(2, :);
% ts_x = extract_stochastic_component();
predSeries = ts_x(N+1:end);
targetSeries = tonndata(ts_x(1:N),true,false);

A=1:length(targetSeries);
% Create a Nonlinear Autoregressive Network
feedbackDelays = 1:2;
hiddenLayerSize = 30;
network = narnet(feedbackDelays,hiddenLayerSize);

% Choose Feedback Pre/Post-Processing Functions
% Settings for feedback input are automatically applied to feedback output
% For a list of all processing functions type: help nnprocess
network.inputs{1}.processFcns = {'removeconstantrows','mapminmax'};

% Prepare the Data for Training and Simulation
% The function PREPARETS prepares timeseries data for a particular network,
% shifting time by the minimum amount to fill input states and layer states.
% Using PREPARETS allows you to keep your original time series data unchanged, while
% easily customizing it for networks with differing numbers of delays, with
% open loop or closed loop feedback modes.
[inputs,inputStates,layerStates,targets] = preparets(network,{},{},targetSeries);

% Setup Division of Data for Training, Validation, Testing
% For a list of all data division functions type: help nndivide
% network.divideFcn = 'dividerand';  % Divide data randomly
% network.divideMode = 'time';  % Divide up every value
network.divideParam.trainRatio = 70/100;
network.divideParam.valRatio = 15/100;
network.divideParam.testRatio = 15/100;

% Choose a Training Function
% For a list of all training functions type: help nntrain
network.trainFcn = 'trainlm';  % Levenberg-Marquardt

% Choose a Performance Function
% For a list of all performance functions type: help nnperformance
network.performFcn = 'mse';  % Mean squared error

% Choose Plot Functions
% For a list of all plot functions type: help nnplot
network.plotFcns = {'plotperform','plottrainstate','plotresponse', ...
  'ploterrcorr', 'plotinerrcorr'};


% Train the Network
[network,tr] = train(network,inputs,targets,inputStates,layerStates);

% Test the Network
outputs = network(inputs,inputStates,layerStates);
errors = gsubtract(targets,outputs)
performance = perform(network,targets,outputs)

% Recalculate Training, Validation and Test Performance
trainTargets = gmultiply(targets,tr.trainMask);
valTargets = gmultiply(targets,tr.valMask);
testTargets = gmultiply(targets,tr.testMask);
trainPerformance = perform(network,trainTargets,outputs)
valPerformance = perform(network,valTargets,outputs)
testPerformance = perform(network,testTargets,outputs)

% View the Network
view(network)

% Plots
% Uncomment these lines to enable various plots.
%figure, plotperform(tr)
%figure, plottrainstate(tr)
%figure, plotresponse(targets,outputs)
%figure, ploterrcorr(errors)
%figure, plotinerrcorr(inputs,errors)

% Closed Loop Network
% Use this network to do multi-step prediction.
% The function CLOSELOOP replaces the feedback input with a direct
% connection from the outout layer.
netc = closeloop(network);
horizon = 50;
Tpred = nan(horizon+10, 1);
Tpred = tonndata(Tpred,false,false);
Tpred(1:10) = targetSeries(end-(10-1):end);
[Xc,Xci,Aci,~] = preparets(netc,{},{},Tpred);
ypred1 = fromnndata(netc(Xc,Xci,Aci),true,false,false)

figure;
plot(predSeries);
hold on;
plot(ypred1);
legend('Target','Pred NaN');





% [x,xi,ai,t] = preparets(network,{},{},targetSeries);
% [y1,xf,af] = network(x,xi,ai);
% %Now the final input and layer states returned by the network are converted to closed-loop form along with the network. The final input states xf and layer states af of the open-loop network become the initial input states xi and layer states ai of the closed-loop network.
% 
% [netc,xi,ai] = closeloop(network,xf,af);
% %Typically use preparets to define initial input and layer states. Since these have already been obtained from the end of the open-loop simulation, you do not need preparets to continue with the 20 step predictions of the closed-loop network.
% x2=num2cell([91,92,93,94,95])
% [y2,xf,af] = netc(x2,xi,ai)
% % Note that you can set x2 to different sequences of inputs to test different scenarios for however many time steps you would like to make predictions. For example, to predict the magnetic levitation system's behavior if 10 random inputs are used:
% figure;
% plot(ts_x(91:95));
% hold on;
% plot(cell2mat(y2));
% legend('Expected','Predicted');


% Early Prediction Network
% For some applications it helps to get the prediction a timestep early.
% The original network returns predicted y(t+1) at the same time it is given y(t+1).
% For some applications such as decision making, it would help to have predicted
% y(t+1) once y(t) is available, but before the actual y(t+1) occurs.
% The network can be made to return its output a timestep early by removing one delay
% so that its minimal tap delay is now 0 instead of 1.  The new network returns the
% same outputs as the original network, but outputs are shifted left one timestep.
nets = removedelay(network);
[xs,xis,ais,ts] = preparets(nets,{},{},targetSeries);
ys = nets(xs,xis,ais);
closedLoopPerformance = perform(network,ts,ys)
