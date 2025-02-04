using {my.test as my} from '../db/data-model';

service CatService {
  @odata.draft.enabled
  entity Tests @(restrict: [{
    grant: '*',
    to   : 'TestManager'

  }])              as projection on my.Tests
    actions {
       @cds.odata.bindingparameter.name: '_it'
       @Common.SideEffects : {
                TargetProperties: ['_it/questions']
                }
        @Common.IsActionCritical:true
      action assignQuestionsToTest(questionsCount : Integer)             returns String;
      action createQuestions(questionText : String, answerText : String) returns String;
    }

  @odata.draft.enabled
  entity Questions @(restrict: [{
    grant: '*',
    to   : 'TestManager'
  }])              as
    projection on my.Questions {
      questionId,
      test,
      text,
      answer
    };

  entity Suppliers as projection on my.Suppliers;
}
