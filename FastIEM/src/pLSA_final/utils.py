# segmentation, stopwords filtering and document-word matrix generating
# [return]:
# N : number of documents
# M : length of dictionary (of topic)-
# word2id : a map mapping terms to their corresponding ids
# id2word : a map mapping ids to terms
# X : document-word matrix, N*M, each line is the number of terms that show up in the document
def initializeParameters():
    for i in range(0, N):
        normalization = sum(lamda[i, :])
        for j in range(0, K):
            lamda[i, j] /= normalization;

    for i in range(0, K):
        normalization = sum(theta[i, :])
        for j in range(0, M):
            theta[i, j] /= normalization;

    
def preprocessing(datasetFilePath, stopwordsFilePath):
    
    # read the stopwords file
    file = codecs.open(stopwordsFilePath, 'r', 'utf-8')
    stopwords = [line.strip() for line in file] 
    file.close()
    
    # read the documents
    file = codecs.open(datasetFilePath, 'r', 'utf-8')
    documents = [document.strip() for document in file] 
    file.close()

    # number of documents
    N = len(documents)

    wordCounts = [];
    word2id = {}
    id2word = {}
    currentId = 0;
    # generate the word2id and id2word maps and count the number of times of words showing up in documents
    for document in documents:
        segList = jieba.cut(document)
        wordCount = {}
        for word in segList:
            word = word.lower().strip()
            if len(word) > 1 and not re.search('[0-9]', word) and word not in stopwords:               
                if word not in word2id.keys():
                    word2id[word] = currentId;
                    id2word[currentId] = word;
                    currentId += 1;
                if word in wordCount:
                    wordCount[word] += 1
                else:
                    wordCount[word] = 1
        wordCounts.append(wordCount);
    
    # length of dictionary
    M = len(word2id)  

    # generate the document-word matrix
    X = zeros([N, M], int8)
    for word in word2id.keys():
        j = word2id[word]
        for i in range(0, N):
            if word in wordCounts[i]:
                X[i, j] = wordCounts[i][word];    

    return N, M, word2id, id2word, X

def EStep():
    for i in range(0, N):
        for j in range(0, M):
            denominator = 0;
            for k in range(0, K):
                p[i, j, k] = theta[k, j] * lamda[i, k];
                denominator += p[i, j, k];
            if denominator == 0:
                for k in range(0, K):
                    p[i, j, k] = 0;
            else:
                for k in range(0, K):
                    p[i, j, k] /= denominator;


def EStep_incremental(index):
    for i in range(0, N):
        for j in range(0, M):
            denominator = 0;
            for k in range(0, K):
                if i in index:
                    p[i, j, k] = theta[k, j] * lamda[i, k];
                else: 
                    p[i, j, k] = oldp[i, j, k]
                denominator += p[i, j, k];
            if denominator == 0:
                for k in range(0, K):
                    p[i, j, k] = 0;
            else:
                for k in range(0, K):
                    p[i, j, k] /= denominator;


def EStep_saga1(index):
    for i in range(0, N):
        for j in range(0, M):
            denominator = 0;
            for k in range(0, K):
                if i in index:
                    p[i, j, k] = theta[k, j] * lamda[i, k];
                else: 
                    p[i, j, k] = oldp[i, j, k]
                denominator += p[i, j, k];
            if denominator == 0:
                for k in range(0, K):
                    p[i, j, k] = 0;
            else:
                for k in range(0, K):
                    p[i, j, k] /= denominator;


def EStep_saga2(index):
    for i in range(0, N):
        for j in range(0, M):
            denominator = 0;
            for k in range(0, K):
                if i in index:
                    p[i, j, k] = p[i, j, k] + 1/N*(theta[k, j] * lamda[i, k] - p[i, j, k]);
                else: 
                    p[i, j, k] = oldp[i, j, k]
                denominator += p[i, j, k];
            if denominator == 0:
                for k in range(0, K):
                    p[i, j, k] = 0;
            else:
                for k in range(0, K):
                    p[i, j, k] /= denominator;


def MStep():
    # update theta
    for k in range(0, K):
        denominator = 0
        for j in range(0, M):
            theta[k, j] = 0
            for i in range(0, N):
                theta[k, j] += X[i, j] * p[i, j, k]
            denominator += theta[k, j]
        if denominator == 0:
            for j in range(0, M): 
                theta[k, j] = 1.0 / M
        else:
            for j in range(0, M):
                theta[k, j] /= denominator
        
    # update lamda
    for i in range(0, N):
        for k in range(0, K):
            lamda[i, k] = 0
            denominator = 0
            for j in range(0, M):
                lamda[i, k] += X[i, j] * p[i, j, k]
                denominator += X[i, j];
            if denominator == 0:
                lamda[i, k] = 1.0 / K
            else:
                lamda[i, k] /= denominator

def MStepsaga(index_i, index_j):
    # update theta
    for i in index_i:
        for j in range(0, M):
            denominator = 0;
            for k in range(0, K):
                h[i, j, k] = listofthetas[i][k, j] * listoflamdas[i, k];
                denominator += h[i, j, k];
            if denominator == 0:
                for k in range(0, K):
                    h[i, j, k] = 0;
            else:
                for k in range(0, K):
                    h[i, j, k] /= denominator;

    for k in range(0, K):
        denominator = 0
        for j in range(0, M):
            theta[k, j] = 0
            tmp = 0
            for i in index_i:
                tmp +=  N*(X[i, j] * p[i, j, k] - X[i, j] * h[i, j, k])
            Vsomme = Hsomme[k,j] + tmp
            Ssomme[k,j] = (1- rho_saga)*Ssomme[k,j] + rho_saga*Vsomme
            theta[k, j] = Ssomme[k,j]
            denominator += theta[k, j]
        if denominator == 0:
            for j in range(0, M): 
                theta[k, j] = 1.0 / M
        else:
            for j in range(0, M):
                theta[k, j] /= denominator
    # update lamda
    for i in range(0, N):
        for k in range(0, K):
            lamda[i, k] = 0
            denominator = 0
            for j in range(0, M):
                # lamda[i, k] += X[i, j] * p[i, j, k]
                lamda[i, k] += 1
                denominator += X[i, j];
            if denominator == 0:
                lamda[i, k] = 1.0 / K
            else:
                lamda[i, k] /= denominator
    for j in range(0, M):
        for k in range(0, K):
            tmph = 0
            for i in index_j:
                h[i, j, k] = listofthetas[i][k, j] * listoflamdas[i, k];
                tmph +=  (X[i, j] * p[i, j, k] - X[i, j] * h[i, j, k])
                Hsomme[k,j] += tmph
    for i in index_j:
        listofthetas[i] = theta
        listoflamdas[i,] = lamda[i,]
   


def MStep_online(index):
    # update theta
    for k in range(0, K):
        denominator = 0
        for j in range(0, M):
            theta[k, j] = 0
            oldsomme = 0
            somme_minibatch = 0
            for i in range(0,N):
                oldsomme += X[i, j] * oldp[i, j, k]
            for i in index:
                somme_minibatch += X[i, j] * p[i, j, k]        
            theta[k, j] += oldsomme + rho[epoch]*(somme_minibatch - oldsomme)
            denominator += theta[k, j]
        if denominator == 0:
            for j in range(0, M):
                theta[k, j] = 1.0 / M
        else:
            for j in range(0, M):
                theta[k, j] /= denominator
        
    # update lamda
    for i in range(0, N):
        for k in range(0, K):
            lamda[i, k] = 0
            denominator = 0
            for j in range(0, M):
                lamda[i, k] += X[i, j] * p[i, j, k]
                denominator += X[i, j];
            if denominator == 0:
                lamda[i, k] = 1.0 / K
            else:
                lamda[i, k] /= denominator

def MStep_onlinevr(index):
    # update theta
    for k in range(0, K):
        denominator = 0
        for j in range(0, M):
            theta[k, j] = 0
            oldsomme = 0
            oldsomme0 = 0
            somme_minibatch = 0
            somme_minibatch0 = 0
            for i in range(0,N):
                oldsomme += X[i, j] * oldp[i, j, k]
                oldsomme0 += X[i, j] * p0[i, j, k]
            for i in index:
                somme_minibatch += X[i, j] * p[i, j, k]
                somme_minibatch0 += X[i, j] * p0[i, j, k]
            theta[k, j] += oldsomme + rho*(somme_minibatch - somme_minibatch0 + oldsomme0 - oldsomme)
            denominator += theta[k, j]
        if denominator == 0:
            for j in range(0, M):
                theta[k, j] = 1.0 / M
        else:
            for j in range(0, M):
                theta[k, j] /= denominator
        
    # update lamda
    for i in range(0, N):
        for k in range(0, K):
            lamda[i, k] = 0
            denominator = 0
            for j in range(0, M):
                lamda[i, k] += X[i, j] * p[i, j, k]
                denominator += X[i, j];
            if denominator == 0:
                lamda[i, k] = 1.0 / K
            else:
                lamda[i, k] /= denominator

# calculate the log likelihood
def LogLikelihood():
    loglikelihood = 0
    for i in range(0, N):
        for j in range(0, M):
            tmp = 0
            for k in range(0, K):
                tmp += theta[k, j] * lamda[i, k]
            if tmp > 0:
                loglikelihood += X[i, j] * log(tmp)
    return loglikelihood

# output the params of model and top words of topics to files
def output():
    # document-topic distribution
    file = codecs.open(docTopicDist,'w','utf-8')
    for i in range(0, N):
        tmp = ''
        for j in range(0, K):
            tmp += str(lamda[i, j]) + ' '
        file.write(tmp + '\n')
    file.close()
    
    # topic-word distribution
    file = codecs.open(topicWordDist,'w','utf-8')
    for i in range(0, K):
        tmp = ''
        for j in range(0, M):
            tmp += str(theta[i, j]) + ' '
        file.write(tmp + '\n')
    file.close()
    
    # dictionary
    file = codecs.open(dictionary,'w','utf-8')
    for i in range(0, M):
        file.write(id2word[i] + '\n')
    file.close()
    
    # top words of each topic
    file = codecs.open(topicWords,'w','utf-8')
    for i in range(0, K):
        topicword = []
        ids = theta[i, :].argsort()
        for j in ids:
            topicword.insert(0, id2word[j])
        tmp = ''
        for word in topicword[0:min(topicWordsNum, len(topicword))]:
            tmp += word + ' '
        file.write(tmp + '\n')
    file.close()