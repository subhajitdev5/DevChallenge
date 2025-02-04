using CatService as service from '../../srv/cat-service';

annotate service.Tests with @(
    UI.LineItem      : [

        {

            $Type: 'UI.DataField',
            Label: 'Title',
            Value: title,

        },
        {
            $Type: 'UI.DataField',
            Label: 'Description',
            Value: description,
        },

        {

            $Type: 'UI.DataField',
            Label: 'Created By',
            Value: createdBy,

        },
        {
            $Type: 'UI.DataField',
            Label: 'Created At',
            Value: createdAt,
        },
        {
            $Type: 'UI.DataField',
            Value: currency_code,
        },
        {
            $Type: 'UI.DataField',
            Value: price,
            Label: 'price',
        },
        {
            $Type: 'UI.DataField',
            Value: supplier.fullName,
            Label: 'Business Partner',
        },
        {
            $Type            : 'UI.DataFieldForAnnotation',
            Label            : 'rating',
            Target           : '@UI.DataPoint#rating',
            ![@UI.Importance]: #High,
        },

    ],
    UI.Identification: [
        {
            $Type : 'UI.DataFieldForAction',
            Action: 'CatService.assignQuestionsToTest',
            Label : 'Assign Questions to Test',
        },

        {
            $Type : 'UI.DataFieldForAction',
            Action: 'CatService.createQuestions',
            Label : 'Create Questions',
        },
    ],
    UI.DataPoint #rating: {
        Value        : rating,
        TargetValue  : 5,
        Visualization: #Rating,
    },
);


annotate service.Tests with @(

    UI.FieldGroup #TestDetails: {

        $Type: 'UI.FieldGroupType',

        Data : [

            {

                $Type: 'UI.DataField',
                Label: 'Title',
                Value: title,

            },
            {
                $Type: 'UI.DataField',
                Label: 'Description',
                Value: description,
            },

            // {

            //     $Type: 'UI.DataField',
            //     Label: 'Created By',
            //     Value: createdBy,

            // },
            // {
            //     $Type : 'UI.DataField',
            //     Label : 'Created At',
            //     Value : createdAt,
            // },
            {
                $Type: 'UI.DataField',
                Label: 'Price',
                Value: price,
            },
            {
                $Type: 'UI.DataField',
                Value: rating,
                Label: 'rating',
            },
            {
                Label: 'Business Partner',
                Value: supplier_ID
            },
            {Value: supplier.isBlocked},

        ],


    },


    UI.Facets                 : [
        {

            $Type : 'UI.ReferenceFacet',
            ID    : 'TestDetailsFacet',
            Label : 'Test Details',
            Target: '@UI.FieldGroup#TestDetails',

        },
        {
            $Type : 'UI.ReferenceFacet',
            Label : 'Questions',
            ID    : 'Questions',
            Target: 'questions/@UI.LineItem#Questions',
        },
    ],


);

annotate service.Questions with @(UI.LineItem #Questions: [
    {
        $Type: 'UI.DataField',
        Value: text,
        Label: 'Questions text',
    },
    {
        $Type: 'UI.DataField',
        Value: answer.text,
        Label: 'Answers text',
    },
]);

annotate service.Tests with {
    price @Measures: {ISOCurrency: currency_code}
}

annotate CatService.Tests with {
    @Common.ValueListWithFixedValues: true
    @Common.ValueList               : {
        $Type         : 'Common.ValueListType',
        Label         : 'Currency',
        CollectionPath: 'Currencies',
        Parameters    : [
            {
                $Type            : 'Common.ValueListParameterInOut',
                LocalDataProperty: currency_code,
                ValueListProperty: 'code'
            },
            {
                $Type            : 'Common.ValueListParameterDisplayOnly',
                ValueListProperty: 'name'
            }
        ]
    }
    @Core.Description               : 'A currency code as specified in ISO 4217'
    currency
};

annotate service.Tests with {
    supplier @(
        Common.ValueList: {
            Label: 'Suppliers',
            CollectionPath: 'Suppliers',
            Parameters: [
                { $Type: 'Common.ValueListParameterInOut',
                    LocalDataProperty: supplier_ID,
                    ValueListProperty: 'ID'
                },
                { $Type: 'Common.ValueListParameterDisplayOnly',
                    ValueListProperty: 'fullName'
                }
            ]
        },
        Common.Text : {
            $value : supplier.fullName,
            ![@UI.TextArrangement] : #TextFirst
        },
    );
}

annotate service.Suppliers with {
    ID@(
        title: 'ID',
        Common.Text: fullName
    );
    fullName    @title: 'Name';
}

annotate service.Suppliers with {
    isBlocked   @title: 'Supplier Blocked';
}

annotate service.Suppliers with @Capabilities.SearchRestrictions.Searchable : false;