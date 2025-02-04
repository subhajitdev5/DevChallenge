const cds = require('@sap/cds');
// const { Tests, Questions, Suppliers} = cds.entities('CatService');

module.exports = class CatService extends cds.ApplicationService {
  async init() {
    const { Tests, Questions, Suppliers } = this.entities;

    this.on('assignQuestionsToTest', 'Tests', async (req) => {
      const testId = req.params[0].testId;
      console.log(req.params)
      const { questionsCount } = req.data;

      if (questionsCount < 1) {
        return req.reject(400, 'questionsCount must be at least 1.');
      }

      if (testId) {
        const test = await SELECT.one.from(Tests).where({ testId: testId });
        if (!test) {
          return req.error(404, `Test with ID ${testId} is not found`);
        }
      }


      const unassociatedQuestions = await cds.transaction(req).run(
        SELECT.from(Questions).where({ test_testId: null }).limit(questionsCount)
      );

      if (unassociatedQuestions.length === 0) {
        return req.reject(
          400,
          'No questions available for assignment. Please create more questions and retry.'
        );
      }


      // const assignedQuestions = unassociatedQuestions.slice(0, questionsCount);
      // const questionIDs = assignedQuestions.map((q) => q.ID);

      const availableQuestionsCount = unassociatedQuestions.length;

      if (availableQuestionsCount < questionsCount) {
        return { message: `${availableQuestionsCount} questions successfully added to the test. The requested ${questionsCount - availableQuestionsCount} questions were not available.` };
      }

      await cds.tx(req).run(
        UPDATE('Questions')
          .set({ test_testId: testId })  // Correct foreign key assignment
          .where({ questionId: { in: unassociatedQuestions.map(q => q.questionId) } })  // Use `questionId` for matching
      );
      const updatedQuestions = await cds.tx(req).run(
        SELECT.from('Questions').where({ test_testId: testId })
      );
      console.log("Updated Questions:", updatedQuestions);  // This will log the questions now associated with the test

      // Update the `lastUpdated` field in the `Tests` table
      await cds.tx(req).run(
        UPDATE('Tests').set({ lastUpdated: new Date() }).where({ testId: testId })
      );

      return { message: `Assigned ${questionsCount} questions successfully to the test.` };
    });



    this.on('createQuestions', 'Tests', async (req) => {
      const questionText = req.data.questionText;
      const answerText = req.data.answerText;

      if (!questionText || !answerText) {
        return req.error(400, 'Both questionText and answerText are required.');
      }
      // Generate a unique ID for the questionId
      const questionId = Math.random().toString(36).substring(2, 10);
      const answerId = Math.random().toString(36).substring(2, 10);

      // Insert the question into the Questions table
      const questions = {
        questionId: questionId,
        text: questionText,
        answers: { answerId: answerId, text: answerText }
      }

      await INSERT(questions).into(Questions);
      console.log(await SELECT.from(Questions));


      return `Question and answer have been successfully created!`;

    });
    const bupa = await cds.connect.to('API_BUSINESS_PARTNER');

    this.on("READ", 'Tests', async (req, next) => {
      if (!req.query.SELECT.columns) return next();
      const expandIndex = req.query.SELECT.columns.findIndex(
        ({ expand, ref }) => expand && ref[0] === "supplier"
      );
      if (expandIndex < 0) return next();

      // Remove expand from query
      req.query.SELECT.columns.splice(expandIndex, 1);

      // Make sure supplier_ID will be returned
      if (!req.query.SELECT.columns.indexOf('*') >= 0 &&
        !req.query.SELECT.columns.find(
          column => column.ref && column.ref.find((ref) => ref == "supplier_ID"))
      ) {
        req.query.SELECT.columns.push({ ref: ["supplier_ID"] });
      }

      const risks = await next();

      const asArray = x => Array.isArray(x) ? x : [x];

      // Request all associated suppliers
      const supplierIds = asArray(risks).map(risk => risk.supplier_ID);
      const suppliers = await bupa.run(SELECT.from(Suppliers).where({ ID: supplierIds }));

      // Convert in a map for easier lookup
      const suppliersMap = {};
      for (const supplier of suppliers)
        suppliersMap[supplier.ID] = supplier;

      // Add suppliers to result
      for (const note of asArray(risks)) {
        note.supplier = suppliersMap[note.supplier_ID];
      }

      return risks;
    });


    this.on('READ', 'Suppliers', async req => {
      return bupa.run(req.query);
    });

    // this.before("UPDATE", "Suppliers", (req) => this.onUpdate(req));
    // this.after("READ", "Suppliers", (data) => this.changeUrgencyDueToSubject(data));
    // // this.on('READ', 'Customers', (req) => this.onCustomerRead(req));
    return super.init();
  }
};