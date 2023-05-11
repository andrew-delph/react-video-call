import * as common from 'common';
import * as funcs from 'neo4jscripts';

common.listenGlobalExceptions();

const logger = common.getLogger();

funcs.setDriver(`bolt://neo4j:7687`); // `bolt://127.0.0.1:7687`

const job = process.env.JOB;

// funcs.createData();
let node_attributes: string[];

const print_num = 5;

const redisClient = common.createRedisClient();

let results;
const start_time = performance.now();
logger.info(`Value of JOB: ${job}`);
(async () => {
  switch (job) {
    case `SHORT_PREDICT`:
      /*
        graph name shortPredictGraph
      */

      const activeUsers = await common.getRecentlyActiveUsers(redisClient, 5);

      if (activeUsers.length < 5) {
        logger.info(`activeUsers.length is too small : ${activeUsers.length}`);
        break;
      } else {
        logger.info(`Recently Active Users: ${activeUsers.length}`);
      }

      const test_attributes: string[] = await funcs.getAttributeKeys();
      results = await funcs.createGraph(`shortPredictGraph`, test_attributes);

      results = await funcs.run(
        `
          CALL gds.articleRank.mutate('shortPredictGraph', {  
              scaler: "MinMax",
              nodeLabels: ['Person'],
              relationshipTypes: ['FRIENDS'],
              mutateProperty: 'priority' 
            }
          )
          YIELD nodePropertiesWritten, ranIterations
        `,
      );

      results = await funcs.run(
        `
          CALL gds.louvain.mutate('shortPredictGraph', 
          {  
            nodeLabels: ['Person'],
            relationshipTypes: ['FRIENDS'],
            mutateProperty: 'community' 
          }
          )
        `,
      );

      results = await funcs.run(
        `
          CALL gds.fastRP.mutate('shortPredictGraph',
          {
            nodeLabels: ['Person'],
            relationshipTypes: ['FEEDBACK'],
            relationshipWeightProperty: 'score',
            featureProperties: ['values','priority','community'],
            propertyRatio: 0.0,
            nodeSelfInfluence: 1.0,
            embeddingDimension: 128,
            randomSeed: 42,
            iterationWeights: ${JSON.stringify([1, 0.5])},
            mutateProperty: 'embedding'
          }
          )
        `,
      );

      results = await funcs.run(
        `
        CALL gds.graph.nodeProperty.stream('shortPredictGraph', 'embedding', ['Person'])
        YIELD nodeId, propertyValue
        RETURN gds.util.asNode(nodeId).userId AS userId, propertyValue AS embedding
        `,
      );

      for (let record of results.records) {
        const userId: string = record.get(`userId`);
        const embedding = record.get(`embedding`);
        await common.writeRedisUserEmbeddings(redisClient, userId, embedding);
      }

      logger.info(`wrote ${results.records.length} embeddings to redis`);

      break;
    case `TRAIN`:
    case `COMPUTE`:
      return;
      // await funcs.createFriends();
      node_attributes = await funcs.getAttributeKeys();
      results = await funcs.createGraph(`myGraph`, node_attributes);
      funcs.printResults(results, print_num);

      // results = await funcs.callShortestPath();
      // funcs.printResults(results, print_num);

      results = await funcs.callPriority();
      funcs.printResults(results, print_num);

      results = await funcs.callCommunities();
      funcs.printResults(results, print_num);

      results = await funcs.callWriteSimilar();
      funcs.printResults(results, print_num);

      results = await funcs.createPipeline();
      funcs.printResults(results, print_num);

      results = await funcs.createGraph(`myGraph`, node_attributes);
      funcs.printResults(results, print_num);
      break;
  }
  switch (job) {
    case `TRAIN`:
      results = await funcs.train();
      funcs.printResults(results, print_num);

    case `COMPUTE`:
      results = await funcs.predict(true, `myGraph`);
      funcs.printResults(results, print_num);

      // results = await funcs.compareTypes();
      // funcs.printResults(results, print_num);
      break;
  }

  const end_time = performance.now();
  logger.info(
    `complted ${job} in ${((end_time - start_time) / 1000).toFixed(1)}secs ${(
      (end_time - start_time) /
      1000 /
      60
    ).toFixed(1)}mins`,
  );
  process.exit(0);
})();
